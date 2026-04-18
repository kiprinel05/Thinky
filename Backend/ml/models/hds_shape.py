"""
HDS (Hand-drawn Shapes) classifier wrapper.

Responsibilities:
  - Load the trained HDSShapeClassifier weights.
  - Preprocess an arbitrary-size RGB drawing to match the HDS convention:
      * grayscale
      * dark strokes on light background
      * cropped to stroke bounding box
      * resized to 70×70 with aspect-preserving padding (centered)
  - Return top class + full probability distribution.
  - Refine `rectangle`→`square` and `ellipse`→`circle` based on aspect ratio of
    the stroke bounding box (the HDS dataset doesn't separate these).
"""
from __future__ import annotations

from pathlib import Path
from typing import Dict, Tuple, Union

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image

from ml.core.base_model import BaseMLModel
from ml.models.definitions import HDSShapeClassifier

# HDS raw class labels (alphabetical — matches ImageFolder default ordering).
HDS_CLASSES = ["ellipse", "other", "rectangle", "triangle"]

# Game-facing labels after aspect-ratio refinement.
GAME_SHAPES = ["triangle", "circle", "square", "rectangle", "ellipse", "other"]

# Aspect ratio band (long-side / short-side) that qualifies as "regular".
REGULAR_ASPECT_MAX = 1.25

# Minimum probability to trust the top prediction. Below this we return "other".
MIN_CONFIDENCE = 0.45


class HDSShapeModel(BaseMLModel):
    """HDS-trained shape classifier with canvas-aware preprocessing."""

    def __init__(self, model_path: Union[str, Path]):
        super().__init__(str(model_path))
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.classes = HDS_CLASSES

    # ------------------------------------------------------------------
    # BaseMLModel API
    # ------------------------------------------------------------------

    def load(self) -> None:
        try:
            self.model = HDSShapeClassifier(num_classes=len(self.classes))
            state_dict = torch.load(self.model_path, map_location=self.device)
            # Allow saving either the raw state_dict or a dict with "state_dict".
            if isinstance(state_dict, dict) and "state_dict" in state_dict:
                state_dict = state_dict["state_dict"]
            self.model.load_state_dict(state_dict)
            self.model.to(self.device)
            self.model.eval()
            self._is_loaded = True
            print(f"[HDSShapeModel] Loaded weights from {self.model_path}")
        except FileNotFoundError:
            self._is_loaded = False
            print(f"[HDSShapeModel] Weights not found at {self.model_path}. "
                  "Run `python -m ml.training.train_hds` first.")
        except Exception as e:
            self._is_loaded = False
            print(f"[HDSShapeModel] Failed to load: {e}")

    def predict(self, input_data: Union[bytes, np.ndarray, Image.Image]) -> Dict:
        """
        Classify a drawing.

        Args:
            input_data: raw PNG/JPG bytes, numpy BGR/RGB array, or PIL Image.

        Returns:
            {
              "shape": final game-facing label (triangle / circle / square /
                       rectangle / ellipse / other),
              "raw_shape": HDS label (ellipse / rectangle / triangle / other),
              "confidence": probability of top class (0-1),
              "probabilities": {class: prob} for all HDS classes,
              "aspect_ratio": long-side / short-side of stroke bounding box,
              "has_strokes": whether we could find a stroke region at all,
            }
        """
        if not self._is_loaded:
            raise RuntimeError(
                "HDSShapeModel is not loaded — train it first or set MODEL_PATH_HDS_SHAPE."
            )

        pil_gray = _to_pil_gray(input_data)
        tensor, aspect, has_strokes = _preprocess_for_hds(pil_gray)

        if not has_strokes:
            return {
                "shape": "other",
                "raw_shape": "other",
                "confidence": 0.0,
                "probabilities": {c: 0.0 for c in self.classes},
                "aspect_ratio": 1.0,
                "has_strokes": False,
            }

        with torch.no_grad():
            logits = self.model(tensor.to(self.device))
            probs = F.softmax(logits, dim=1).cpu().numpy()[0]

        top_idx = int(np.argmax(probs))
        top_class = self.classes[top_idx]
        top_prob = float(probs[top_idx])

        # Confidence gate — treat very uncertain predictions as "other".
        if top_prob < MIN_CONFIDENCE:
            final_shape = "other"
        else:
            final_shape = _refine_with_aspect(top_class, aspect)

        return {
            "shape": final_shape,
            "raw_shape": top_class,
            "confidence": round(top_prob, 4),
            "probabilities": {c: round(float(p), 4)
                              for c, p in zip(self.classes, probs)},
            "aspect_ratio": round(aspect, 3),
            "has_strokes": True,
        }


# ---------------------------------------------------------------------------
# Preprocessing helpers
# ---------------------------------------------------------------------------

def _to_pil_gray(input_data: Union[bytes, np.ndarray, Image.Image]) -> Image.Image:
    """Accept bytes / ndarray (BGR or RGB) / PIL Image, return grayscale PIL."""
    import io

    if isinstance(input_data, bytes):
        image = Image.open(io.BytesIO(input_data)).convert("L")
    elif isinstance(input_data, np.ndarray):
        arr = input_data
        if arr.ndim == 3 and arr.shape[2] == 3:
            # Assume BGR when coming from cv2.imdecode, which is the usual source.
            arr = arr[..., ::-1]  # → RGB
            image = Image.fromarray(arr).convert("L")
        elif arr.ndim == 2:
            image = Image.fromarray(arr).convert("L")
        else:
            raise ValueError(f"Unsupported array shape: {arr.shape}")
    elif isinstance(input_data, Image.Image):
        image = input_data.convert("L")
    else:
        raise ValueError(f"Unsupported input type: {type(input_data)}")
    return image


def _preprocess_for_hds(
    pil_gray: Image.Image,
) -> Tuple[torch.Tensor, float, bool]:
    """
    Turn an arbitrary canvas image into a 1×1×70×70 tensor matching HDS conventions.

    Steps:
      1. Heuristic: detect if strokes are dark-on-light or light-on-dark (corner
         samples) and invert so we end up with dark strokes on white bg.
      2. Binary mask of strokes (Otsu threshold).
      3. Compute stroke bounding box (+ 4px padding).
      4. Crop. If empty, signal has_strokes=False.
      5. Pad to square (white) to preserve aspect, then resize to 70×70.
      6. Normalize to [0,1] float, 1 channel, add batch dim.

    Returns:
      (tensor [1,1,70,70], aspect_ratio of stroke bbox, has_strokes).
    """
    arr = np.asarray(pil_gray, dtype=np.uint8)

    # Detect background brightness from 4 corners.
    h, w = arr.shape
    s = max(5, min(h, w) // 20)
    corners = np.concatenate([
        arr[:s, :s].ravel(),
        arr[:s, -s:].ravel(),
        arr[-s:, :s].ravel(),
        arr[-s:, -s:].ravel(),
    ])
    bg_bright = float(corners.mean())

    # Normalize to dark-strokes-on-white (HDS convention).
    if bg_bright < 128:
        arr = 255 - arr

    # Otsu threshold → binary mask of strokes (255 where stroke is).
    try:
        import cv2
        _, mask = cv2.threshold(arr, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    except ImportError:  # pragma: no cover — cv2 is a hard dep but be defensive
        mask = (arr < 128).astype(np.uint8) * 255

    ys, xs = np.where(mask > 0)
    if len(xs) == 0:
        # No strokes found — return a blank tensor, caller will handle it.
        blank = torch.ones((1, 1, 70, 70), dtype=torch.float32)
        return blank, 1.0, False

    pad = 4
    x0 = max(int(xs.min()) - pad, 0)
    y0 = max(int(ys.min()) - pad, 0)
    x1 = min(int(xs.max()) + pad + 1, w)
    y1 = min(int(ys.max()) + pad + 1, h)

    crop = arr[y0:y1, x0:x1]
    ch, cw = crop.shape
    aspect = max(ch, cw) / max(min(ch, cw), 1)

    # Pad to square with white (255) so resize doesn't distort the shape.
    side = max(ch, cw)
    square = np.full((side, side), 255, dtype=np.uint8)
    oy = (side - ch) // 2
    ox = (side - cw) // 2
    square[oy:oy + ch, ox:ox + cw] = crop

    pil = Image.fromarray(square).resize((70, 70), Image.LANCZOS)
    tensor = torch.from_numpy(np.asarray(pil, dtype=np.float32) / 255.0)
    tensor = tensor.unsqueeze(0).unsqueeze(0)  # [1, 1, 70, 70]
    return tensor, float(aspect), True


def _refine_with_aspect(hds_class: str, aspect: float) -> str:
    """
    HDS lumps square into "rectangle" and circle into "ellipse".
    Use the stroke bounding-box aspect ratio to disambiguate:
      - rectangle with aspect ≤ 1.25 → square
      - ellipse   with aspect ≤ 1.25 → circle
    """
    if hds_class == "rectangle":
        return "square" if aspect <= REGULAR_ASPECT_MAX else "rectangle"
    if hds_class == "ellipse":
        return "circle" if aspect <= REGULAR_ASPECT_MAX else "ellipse"
    return hds_class
