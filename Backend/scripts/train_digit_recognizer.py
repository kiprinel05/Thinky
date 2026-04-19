"""Train the digit recognizer used by the Numbers mission.

Trains a small CNN on MNIST. Optionally augments the training set with the
Kaggle dataset "Handwritten Digits Dataset (not in MNIST)" by jcprogjava:

    https://www.kaggle.com/datasets/jcprogjava/handwritten-digits-dataset-not-in-mnist

Download the zip from Kaggle and extract it; the resulting folder must contain
sub-folders named ``0/``, ``1/``, ..., ``9/`` (one per class). Pass that folder
via ``--kaggle``.

Usage (from the ``Backend/`` directory):

    # MNIST only — quick, ~3 min on CPU
    python -m scripts.train_digit_recognizer

    # MNIST + Kaggle (more robust to messy hand-drawing)
    python -m scripts.train_digit_recognizer --kaggle path/to/extracted/kaggle/dataset

    # More epochs / different batch size
    python -m scripts.train_digit_recognizer --epochs 10 --batch-size 256

The trained model is saved to ``Backend/features/numbers/models/digit_cnn.pt``
and is loaded automatically by ``DigitRecognitionService`` at startup.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Optional

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from PIL import Image
from torch.utils.data import ConcatDataset, DataLoader, Dataset
from torchvision import datasets, transforms
from tqdm import tqdm


# ── Architecture (kept in sync with digit_recognition.py) ──────────────────────


class DigitCNN(nn.Module):
    """Tiny CNN: ~420K params, ~99% on MNIST, fits in well under 2 MB on disk."""

    def __init__(self) -> None:
        super().__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, padding=1)
        self.conv2 = nn.Conv2d(32, 64, 3, padding=1)
        self.pool = nn.MaxPool2d(2, 2)
        self.fc1 = nn.Linear(64 * 7 * 7, 128)
        self.fc2 = nn.Linear(128, 10)
        self.dropout = nn.Dropout(0.3)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.pool(torch.relu(self.conv1(x)))
        x = self.pool(torch.relu(self.conv2(x)))
        x = x.view(x.size(0), -1)
        x = torch.relu(self.fc1(x))
        x = self.dropout(x)
        return self.fc2(x)


# ── Kaggle dataset wrapper ─────────────────────────────────────────────────────


class KaggleDigitsDataset(Dataset):
    """Loads images from a Kaggle dataset organised as 0/, 1/, ..., 9/.

    The Kaggle "not in MNIST" set ships images with various conventions
    (dark-on-light vs light-on-dark, varying sizes). We auto-invert based on
    mean intensity so everything ends up MNIST-style (light strokes on a dark
    background) before the shared transform runs.
    """

    EXTS = (".png", ".jpg", ".jpeg", ".bmp")

    def __init__(self, root: Path, transform: transforms.Compose) -> None:
        self.transform = transform
        self.samples: list[tuple[Path, int]] = []
        for digit in range(10):
            d = root / str(digit)
            if not d.exists():
                continue
            # Walk recursively — some Kaggle dumps add an extra nested folder
            # (e.g. dataset/0/0/*.png), others put images directly under 0/.
            for p in d.rglob("*"):
                if p.is_file() and p.suffix.lower() in self.EXTS:
                    self.samples.append((p, digit))
        if not self.samples:
            raise ValueError(
                f"No images found under {root}. "
                f"Expected sub-folders named 0/, 1/, ..., 9/ "
                f"(images may be directly inside or one level deeper)."
            )

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, i: int):
        path, label = self.samples[i]
        img = Image.open(path).convert("L")
        arr = np.array(img, dtype=np.uint8)
        # MNIST is light-on-dark. If this image is dark-on-light, invert.
        if arr.mean() > 127:
            img = Image.fromarray(255 - arr)
        return self.transform(img), label


# ── Training loop ──────────────────────────────────────────────────────────────


def build_transform() -> transforms.Compose:
    return transforms.Compose([
        transforms.Resize((28, 28)),
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,)),  # MNIST stats
    ])


def train(
    kaggle_dir: Optional[str],
    epochs: int,
    batch_size: int,
    lr: float,
    output: Optional[Path] = None,
    num_workers: int = 0,
) -> Path:
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    use_cuda = device.type == "cuda"
    if use_cuda:
        print(f"Device: {device} ({torch.cuda.get_device_name(0)})")
        # Speed up convolutions with cuDNN autotuner.
        torch.backends.cudnn.benchmark = True
    else:
        print(f"Device: {device}")

    transform = build_transform()

    cache_dir = Path(__file__).resolve().parent.parent / ".cache" / "datasets"
    cache_dir.mkdir(parents=True, exist_ok=True)

    print("Loading MNIST (will auto-download to .cache/ on first run)...")
    train_mnist = datasets.MNIST(
        str(cache_dir), train=True, download=True, transform=transform
    )
    test_mnist = datasets.MNIST(
        str(cache_dir), train=False, download=True, transform=transform
    )

    train_set: Dataset = train_mnist
    if kaggle_dir:
        kdir = Path(kaggle_dir).expanduser().resolve()
        if not kdir.exists():
            sys.exit(f"Kaggle directory not found: {kdir}")
        print(f"Adding Kaggle dataset from {kdir}...")
        kaggle = KaggleDigitsDataset(kdir, transform)
        print(f"  Kaggle samples: {len(kaggle)}")
        train_set = ConcatDataset([train_mnist, kaggle])

    print(f"Training on {len(train_set)} examples (held-out MNIST test: {len(test_mnist)})")

    loader_kwargs = dict(
        batch_size=batch_size,
        num_workers=num_workers,
        pin_memory=use_cuda,
        persistent_workers=num_workers > 0,
    )
    train_loader = DataLoader(train_set, shuffle=True, **loader_kwargs)
    test_loader = DataLoader(test_mnist, **loader_kwargs)

    model = DigitCNN().to(device)
    optimizer = optim.Adam(model.parameters(), lr=lr)
    criterion = nn.CrossEntropyLoss()

    for epoch in range(1, epochs + 1):
        model.train()
        running = 0.0
        seen = 0
        for xb, yb in tqdm(train_loader, desc=f"Epoch {epoch}/{epochs}"):
            xb = xb.to(device, non_blocking=use_cuda)
            yb = yb.to(device, non_blocking=use_cuda)
            optimizer.zero_grad(set_to_none=True)
            out = model(xb)
            loss = criterion(out, yb)
            loss.backward()
            optimizer.step()
            running += loss.item() * xb.size(0)
            seen += xb.size(0)
        avg_loss = running / max(seen, 1)

        model.eval()
        correct = 0
        with torch.no_grad():
            for xb, yb in test_loader:
                xb = xb.to(device, non_blocking=use_cuda)
                yb = yb.to(device, non_blocking=use_cuda)
                pred = model(xb).argmax(1)
                correct += (pred == yb).sum().item()
        acc = correct / len(test_mnist)
        print(f"  -> train loss={avg_loss:.4f}, MNIST test acc={acc * 100:.2f}%")

    output = output or (
        Path(__file__).resolve().parent.parent
        / "features"
        / "numbers"
        / "models"
        / "digit_cnn.pt"
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    torch.save(model.state_dict(), output)
    size_kb = output.stat().st_size / 1024
    print(f"\n[OK] Saved model to {output} ({size_kb:.1f} KB)")
    return output


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument(
        "--kaggle",
        help=(
            "Path to the extracted Kaggle 'not in MNIST' dataset "
            "(folder containing 0/, 1/, ..., 9/ sub-folders)."
        ),
    )
    ap.add_argument("--epochs", type=int, default=5)
    ap.add_argument(
        "--batch-size",
        type=int,
        default=256,
        help="Default 256 (works fine on 4 GB GPUs); drop to 128 if you hit OOM.",
    )
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument(
        "--num-workers",
        type=int,
        default=0,
        help=(
            "DataLoader workers. Keep at 0 on Windows unless you know what "
            "you're doing — multiprocessing on Windows is finicky."
        ),
    )
    ap.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Optional override for the output .pt path.",
    )
    args = ap.parse_args()
    train(
        args.kaggle,
        args.epochs,
        args.batch_size,
        args.lr,
        args.output,
        args.num_workers,
    )


if __name__ == "__main__":
    main()
