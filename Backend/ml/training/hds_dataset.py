"""
PyTorch Dataset for the Hand-drawn Shapes (HDS) dataset.

The HDS repo organizes images by user and class:
  data/<user>/images/<class>/<class>.<user>.XXXX.png

Images are 70×70 grayscale (dark strokes on white), one shape per file.
Classes: ellipse, other, rectangle, triangle (alphabetical → integer labels).
"""
from __future__ import annotations

from pathlib import Path
from typing import Callable, List, Optional, Tuple

import numpy as np
import torch
from PIL import Image
from torch.utils.data import Dataset

CLASSES = ["ellipse", "other", "rectangle", "triangle"]
CLASS_TO_IDX = {c: i for i, c in enumerate(CLASSES)}


class HDSDataset(Dataset):
    """
    Walks an HDS clone and yields (image_tensor, label_idx) pairs.

    Args:
        root: path to the repo root OR the data/ subdirectory.
        transform: optional torchvision transform applied to the PIL image.
                   If None, a default "to float tensor in [0,1]" is used.
        include_users: optional list of user directories to include (for splitting).
                       If None, all users are included.
    """

    def __init__(
        self,
        root: Path,
        transform: Optional[Callable] = None,
        include_users: Optional[List[str]] = None,
    ):
        root = Path(root).resolve()
        if (root / "data").is_dir():
            root = root / "data"
        if not root.is_dir():
            raise FileNotFoundError(f"HDS data directory not found at {root}")

        self.root = root
        self.transform = transform
        self.samples: List[Tuple[Path, int]] = []

        user_dirs = [p for p in root.iterdir() if p.is_dir()]
        if include_users is not None:
            wanted = set(include_users)
            user_dirs = [p for p in user_dirs if p.name in wanted]

        for user in user_dirs:
            images_root = user / "images"
            if not images_root.is_dir():
                continue
            for class_dir in images_root.iterdir():
                if not class_dir.is_dir():
                    continue
                class_name = class_dir.name.lower()
                if class_name not in CLASS_TO_IDX:
                    continue  # ignore unknown folders
                label = CLASS_TO_IDX[class_name]
                for png in class_dir.glob("*.png"):
                    self.samples.append((png, label))

        if not self.samples:
            raise RuntimeError(
                f"HDSDataset found no images under {root}. "
                "Did you run `python -m ml.training.download_hds`?"
            )

    @staticmethod
    def list_users(root: Path) -> List[str]:
        """Return sorted list of user directory names at the HDS root."""
        root = Path(root).resolve()
        if (root / "data").is_dir():
            root = root / "data"
        return sorted(p.name for p in root.iterdir() if p.is_dir())

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> Tuple[torch.Tensor, int]:
        path, label = self.samples[idx]
        image = Image.open(path).convert("L")  # 1 channel, 0-255

        if self.transform is not None:
            image = self.transform(image)
        else:
            arr = np.asarray(image, dtype=np.float32) / 255.0
            image = torch.from_numpy(arr).unsqueeze(0)  # [1,H,W]

        return image, label

    # Useful for reporting class balance in the training script.
    def class_counts(self) -> dict[str, int]:
        counts = {c: 0 for c in CLASSES}
        for _, label in self.samples:
            counts[CLASSES[label]] += 1
        return counts
