"""
Download the Hand-drawn Shapes (HDS) dataset from GitHub.

Source: https://github.com/frobertpixto/hand-drawn-shapes-dataset
License: MIT (see upstream repo).

Usage (from Backend/ working directory):
  python -m ml.training.download_hds
  python -m ml.training.download_hds --dest ml/datasets/hds

On re-runs, the script detects an existing clone and performs `git pull`
instead of re-cloning.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

REPO_URL = "https://github.com/frobertpixto/hand-drawn-shapes-dataset.git"
DEFAULT_DEST = Path(__file__).resolve().parents[2] / "ml" / "datasets" / "hds"


def _run(cmd: list[str], cwd: Path | None = None) -> None:
    print(f"[hds-download] $ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=True)


def ensure_git_available() -> None:
    if shutil.which("git") is None:
        sys.exit(
            "[hds-download] git is not installed or not on PATH. "
            "Install it from https://git-scm.com/ and re-run."
        )


def clone_or_update(dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)

    if (dest / ".git").exists():
        print(f"[hds-download] Existing clone at {dest} — pulling latest.")
        _run(["git", "pull", "--ff-only"], cwd=dest)
    else:
        if dest.exists() and any(dest.iterdir()):
            sys.exit(
                f"[hds-download] {dest} exists and is not a git clone. "
                "Remove it or pick another --dest."
            )
        _run(["git", "clone", "--depth", "1", REPO_URL, str(dest)])


def verify_structure(dest: Path) -> None:
    data_root = dest / "data"
    if not data_root.is_dir():
        sys.exit(f"[hds-download] Unexpected layout: no data/ directory at {data_root}")

    users = [p for p in data_root.iterdir() if p.is_dir()]
    if not users:
        sys.exit(f"[hds-download] No user directories under {data_root}")

    # Count images per class by scanning user/images/<class>/*.png.
    class_counts: dict[str, int] = {}
    for user in users:
        images_root = user / "images"
        if not images_root.is_dir():
            continue
        for class_dir in images_root.iterdir():
            if class_dir.is_dir():
                n = sum(1 for p in class_dir.glob("*.png"))
                class_counts[class_dir.name] = class_counts.get(class_dir.name, 0) + n

    total = sum(class_counts.values())
    print(f"[hds-download] Clone OK at {dest}")
    print(f"[hds-download] Total images: {total}")
    for name, count in sorted(class_counts.items()):
        print(f"  - {name:12s} {count}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dest", type=Path, default=DEFAULT_DEST,
                        help=f"Where to clone the dataset (default: {DEFAULT_DEST}).")
    args = parser.parse_args()

    ensure_git_available()
    clone_or_update(args.dest.resolve())
    verify_structure(args.dest.resolve())


if __name__ == "__main__":
    main()
