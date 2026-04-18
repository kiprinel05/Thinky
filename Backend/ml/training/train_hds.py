"""
Train the HDSShapeClassifier on the Hand-drawn Shapes (HDS) dataset.

Usage (from Backend/):
  python -m ml.training.train_hds                       # defaults
  python -m ml.training.train_hds --epochs 15 --lr 5e-4
  python -m ml.training.train_hds --hds-root ml/datasets/hds

The dataset is split BY USER to avoid leakage — the model never sees samples
from a val-set user during training. This gives a realistic estimate of how
well it will generalize to a new player.

Artifacts are saved to:
  ml/artifacts/hds_shape_model.pth       (state_dict)
  ml/artifacts/hds_shape_model.meta.json (classes + metrics)
"""
from __future__ import annotations

import argparse
import json
import random
import sys
import time
from pathlib import Path
from typing import List, Tuple

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader
from torchvision import transforms

# Make "ml" importable when running as `python -m ml.training.train_hds`
# from the Backend/ directory.
THIS_DIR = Path(__file__).resolve().parent
BACKEND_DIR = THIS_DIR.parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from ml.models.definitions import HDSShapeClassifier  # noqa: E402
from ml.training.hds_dataset import CLASSES, HDSDataset  # noqa: E402


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

DEFAULT_HDS_ROOT = BACKEND_DIR / "ml" / "datasets" / "hds"
ARTIFACTS_DIR = BACKEND_DIR / "ml" / "artifacts"
DEFAULT_WEIGHTS = ARTIFACTS_DIR / "hds_shape_model.pth"
DEFAULT_META = ARTIFACTS_DIR / "hds_shape_model.meta.json"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--hds-root", type=Path, default=DEFAULT_HDS_ROOT,
                   help="Path to the HDS clone (folder containing data/).")
    p.add_argument("--out", type=Path, default=DEFAULT_WEIGHTS,
                   help="Path for the saved state_dict.")
    p.add_argument("--epochs", type=int, default=25)
    p.add_argument("--batch-size", type=int, default=128)
    p.add_argument("--lr", type=float, default=1e-3)
    p.add_argument("--weight-decay", type=float, default=1e-4)
    p.add_argument("--val-frac", type=float, default=0.15,
                   help="Fraction of USERS (not images) held out for validation.")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--num-workers", type=int, default=0,
                   help="DataLoader workers (0 works best on Windows).")
    p.add_argument("--device", type=str, default=None,
                   help="Override device. Defaults to cuda if available.")
    return p.parse_args()


# ---------------------------------------------------------------------------
# Transforms
# ---------------------------------------------------------------------------

def build_transforms(training: bool) -> transforms.Compose:
    """
    HDS images are already 70×70 grayscale, so we mostly just augment.

    Training augmentations:
      - small rotations (±12°)
      - small translations / scale jitter (RandomAffine)
      - random erasing (simulates stroke dropouts from fast drawing)

    All shapes end up as a [1,70,70] float tensor in [0,1].
    """
    tfs: list = []
    if training:
        # Gentle augmentations — HDS shapes are already size-normalized and
        # centered. Stronger affine transforms (e.g. ±12°) pushed rotated
        # rectangles into the "triangle" class during training.
        tfs.append(transforms.RandomAffine(
            degrees=8,
            translate=(0.04, 0.04),
            scale=(0.92, 1.08),
            fill=255,  # HDS convention: white background
        ))
    tfs.append(transforms.ToTensor())  # → [0,1] float, [C=1,H,W]
    if training:
        tfs.append(transforms.RandomErasing(p=0.10, scale=(0.01, 0.03),
                                            ratio=(0.3, 3.3), value=1.0))
    return transforms.Compose(tfs)


# ---------------------------------------------------------------------------
# User-based split
# ---------------------------------------------------------------------------

def split_users(root: Path, val_frac: float, seed: int) -> Tuple[List[str], List[str]]:
    users = HDSDataset.list_users(root)
    if not users:
        sys.exit(f"[train-hds] No users found at {root}")
    rng = random.Random(seed)
    shuffled = list(users)
    rng.shuffle(shuffled)
    n_val = max(1, int(round(len(shuffled) * val_frac)))
    val_users = sorted(shuffled[:n_val])
    train_users = sorted(shuffled[n_val:])
    print(f"[train-hds] Users: {len(users)} total → "
          f"{len(train_users)} train, {len(val_users)} val")
    return train_users, val_users


# ---------------------------------------------------------------------------
# Train / eval loops
# ---------------------------------------------------------------------------

def train_one_epoch(model, loader, criterion, optimizer, device) -> Tuple[float, float]:
    model.train()
    total_loss = 0.0
    correct = 0
    seen = 0
    for images, labels in loader:
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        optimizer.zero_grad()
        logits = model(images)
        loss = criterion(logits, labels)
        loss.backward()
        optimizer.step()

        total_loss += loss.item() * images.size(0)
        correct += (logits.argmax(1) == labels).sum().item()
        seen += images.size(0)
    return total_loss / seen, correct / seen


@torch.no_grad()
def evaluate(model, loader, criterion, device) -> Tuple[float, float, np.ndarray]:
    model.eval()
    total_loss = 0.0
    correct = 0
    seen = 0
    confusion = np.zeros((len(CLASSES), len(CLASSES)), dtype=np.int64)
    for images, labels in loader:
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        logits = model(images)
        loss = criterion(logits, labels)

        preds = logits.argmax(1)
        total_loss += loss.item() * images.size(0)
        correct += (preds == labels).sum().item()
        seen += images.size(0)

        for t, p in zip(labels.cpu().numpy(), preds.cpu().numpy()):
            confusion[t, p] += 1
    return total_loss / seen, correct / seen, confusion


def print_confusion(confusion: np.ndarray) -> None:
    header = "           " + "  ".join(f"{c:>10s}" for c in CLASSES)
    print(header)
    for i, row_name in enumerate(CLASSES):
        row_total = confusion[i].sum() or 1
        cells = "  ".join(f"{confusion[i, j]:4d} ({100*confusion[i,j]/row_total:5.1f}%)"
                          for j in range(len(CLASSES)))
        print(f"  {row_name:>8s}  {cells}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_args()

    torch.manual_seed(args.seed)
    np.random.seed(args.seed)
    random.seed(args.seed)

    device = torch.device(
        args.device if args.device is not None
        else ("cuda" if torch.cuda.is_available() else "cpu")
    )
    print(f"[train-hds] device: {device}")

    train_users, val_users = split_users(args.hds_root, args.val_frac, args.seed)

    train_set = HDSDataset(args.hds_root,
                           transform=build_transforms(training=True),
                           include_users=train_users)
    val_set = HDSDataset(args.hds_root,
                         transform=build_transforms(training=False),
                         include_users=val_users)

    print(f"[train-hds] train samples: {len(train_set)} — class counts: "
          f"{train_set.class_counts()}")
    print(f"[train-hds] val   samples: {len(val_set)} — class counts: "
          f"{val_set.class_counts()}")

    pin = device.type == "cuda"
    train_loader = DataLoader(train_set, batch_size=args.batch_size,
                              shuffle=True, num_workers=args.num_workers,
                              pin_memory=pin)
    val_loader = DataLoader(val_set, batch_size=args.batch_size,
                            shuffle=False, num_workers=args.num_workers,
                            pin_memory=pin)

    model = HDSShapeClassifier(num_classes=len(CLASSES)).to(device)
    n_params = sum(p.numel() for p in model.parameters())
    print(f"[train-hds] model params: {n_params/1000:.1f}k")

    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.parameters(),
                                  lr=args.lr, weight_decay=args.weight_decay)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=args.epochs)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    best_val_acc = 0.0
    best_confusion = None

    for epoch in range(1, args.epochs + 1):
        t0 = time.time()
        train_loss, train_acc = train_one_epoch(model, train_loader, criterion,
                                                 optimizer, device)
        val_loss, val_acc, confusion = evaluate(model, val_loader, criterion, device)
        scheduler.step()

        dt = time.time() - t0
        print(f"Epoch {epoch:2d}/{args.epochs} | "
              f"train loss {train_loss:.4f} acc {train_acc*100:5.2f}% | "
              f"val loss {val_loss:.4f} acc {val_acc*100:5.2f}% | "
              f"{dt:5.1f}s")

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            best_confusion = confusion
            torch.save(model.state_dict(), args.out)
            print(f"  ↳ saved best weights → {args.out}")

    print("\n[train-hds] Best val accuracy: "
          f"{best_val_acc*100:.2f}%")
    if best_confusion is not None:
        print("[train-hds] Confusion matrix (rows = true, cols = predicted):")
        print_confusion(best_confusion)

    meta = {
        "classes": CLASSES,
        "best_val_accuracy": round(float(best_val_acc), 4),
        "epochs": args.epochs,
        "batch_size": args.batch_size,
        "learning_rate": args.lr,
        "weight_decay": args.weight_decay,
        "val_fraction": args.val_frac,
        "seed": args.seed,
        "train_users": train_users,
        "val_users": val_users,
        "train_size": len(train_set),
        "val_size": len(val_set),
    }
    meta_path = args.out.with_suffix(".meta.json")
    meta_path.write_text(json.dumps(meta, indent=2))
    print(f"[train-hds] Meta written to {meta_path}")


if __name__ == "__main__":
    main()
