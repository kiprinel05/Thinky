"""
Drawing analysis service.

Architecture:
  - Shape detection  →  CNN trained on the Hand-drawn Shapes (HDS) dataset.
  - Color detection  →  K-means on HSV pixels inside the stroke region.
  - Edge cases       →  empty canvas / scribble / too small.

The CNN replaces the previous 4-strategy OpenCV consensus, which struggled
with hand-drawn shapes whose corners were slightly rounded (a triangle could
be mis-classified as a square).

Required model artifact: `ml/artifacts/hds_shape_model.pth` — train it with
`python -m ml.training.train_hds` from the Backend/ directory.
"""
from __future__ import annotations

from typing import Dict, Optional, Tuple

import cv2
import numpy as np

from core.config import settings
from features.drawing.schemas import DrawingAnalysisResponse
from ml.models.hds_shape import HDSShapeModel

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

# What the game currently supports asking the user to draw.
SUPPORTED_SHAPES = ["triangle", "circle", "square", "rectangle", "ellipse"]

# Game-level aliases: a "rectangle" drawing is acceptable as "square" if the
# user hasn't strictly drawn a square, and vice-versa. Flutter rounds always
# target strict shapes, so this is only a safety net.
SHAPE_ALIASES: Dict[str, list[str]] = {
    "rectangle": ["square"],
    "square": ["rectangle"],
    "ellipse": ["circle"],
    "circle": ["ellipse"],
}

# Named colors as HSV centroids (H 0-180, S 0-255, V 0-255).
NAMED_COLORS_HSV = {
    "red":    (  0, 220, 220),
    "orange": ( 15, 220, 230),
    "yellow": ( 28, 200, 240),
    "green":  ( 60, 180, 180),
    "blue":   (110, 200, 220),
    "purple": (140, 180, 180),
    "black":  (  0,   0,  30),
}

# Minimum drawing presence to even run classification.
MIN_CANVAS_RATIO = 0.005           # stroke pixels / total pixels
SCRIBBLE_SOLIDITY_THRESHOLD = 0.25 # contour area / hull area
MIN_COVERAGE_FILL = 0.08           # only enforced when require_fill=True


# ---------------------------------------------------------------------------
# Stroke mask / contour helpers
# ---------------------------------------------------------------------------

def _background_corrected_gray(bgr: np.ndarray) -> Tuple[np.ndarray, bool]:
    """Return a grayscale image with dark strokes on white bg (inverted if needed)."""
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape
    s = max(5, min(h, w) // 20)
    corners = np.concatenate([
        gray[:s, :s].ravel(),
        gray[:s, -s:].ravel(),
        gray[-s:, :s].ravel(),
        gray[-s:, -s:].ravel(),
    ])
    inverted = corners.mean() < 128
    if inverted:
        gray = cv2.bitwise_not(gray)
    return gray, inverted


def _stroke_mask(gray_dark_on_light: np.ndarray) -> np.ndarray:
    """Otsu threshold → binary mask where 255 = stroke pixel."""
    blurred = cv2.GaussianBlur(gray_dark_on_light, (3, 3), 0)
    _, mask = cv2.threshold(blurred, 0, 255,
                            cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    # Tiny dilation to bridge pixel-level jitter. Deliberately small so corners
    # stay sharp (see rounded-corner bug that affected the old pipeline).
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    return cv2.dilate(mask, kernel, iterations=1)


def _largest_external_contour(mask: np.ndarray) -> Optional[np.ndarray]:
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL,
                                   cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None
    # If strokes are disconnected, merge everything into a convex hull so that
    # scribble/too-small checks reflect the whole drawing.
    if len(contours) == 1:
        return contours[0]
    all_pts = np.vstack(contours)
    return cv2.convexHull(all_pts)


def _is_scribble(contour: np.ndarray) -> bool:
    area = cv2.contourArea(contour)
    hull_area = cv2.contourArea(cv2.convexHull(contour))
    if hull_area < 1:
        return True
    return (area / hull_area) < SCRIBBLE_SOLIDITY_THRESHOLD


def _is_too_small(contour: np.ndarray, img_shape: tuple) -> bool:
    area = cv2.contourArea(contour)
    total = img_shape[0] * img_shape[1]
    return (area / total) < MIN_CANVAS_RATIO


def _coverage(mask: np.ndarray) -> float:
    total = mask.shape[0] * mask.shape[1]
    return float(cv2.countNonZero(mask)) / total if total else 0.0


def _crop_to_contour_bbox(
    image_bgr: np.ndarray, contour: np.ndarray, margin: float = 0.15
) -> np.ndarray:
    """
    Crop the input image around the main contour with a relative margin.

    Args:
        image_bgr: full BGR image from cv2.imdecode.
        contour: main stroke contour (from _largest_external_contour).
        margin: fraction of the bbox's longer side added as padding on each
                side. 0.15 means 15% margin, matching HDS-style centered shapes.

    Returns:
        A cropped BGR ndarray containing just the shape region with padding,
        clamped to the image boundaries. Falls back to the full image if the
        contour is degenerate.
    """
    h, w = image_bgr.shape[:2]
    x, y, bw, bh = cv2.boundingRect(contour)
    if bw <= 0 or bh <= 0:
        return image_bgr
    pad = int(round(max(bw, bh) * margin))
    x0 = max(x - pad, 0)
    y0 = max(y - pad, 0)
    x1 = min(x + bw + pad, w)
    y1 = min(y + bh + pad, h)
    return image_bgr[y0:y1, x0:x1]


# ---------------------------------------------------------------------------
# K-means color detection (unchanged from the OpenCV service — works well)
# ---------------------------------------------------------------------------

def _detect_color_kmeans(
    image_bgr: np.ndarray, mask: np.ndarray
) -> Tuple[str, float, Dict[str, float]]:
    """
    Run K-means on HSV pixels inside the stroke mask and map the dominant
    cluster centroid to the nearest named color.
    """
    hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    pixels = hsv[mask > 0].reshape(-1, 3).astype(np.float32)

    if len(pixels) < 20:
        return "unknown", 0.0, {}

    k = min(3, len(pixels))
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0)
    _, labels, centers = cv2.kmeans(pixels, k, None, criteria, 5,
                                    cv2.KMEANS_PP_CENTERS)

    counts = np.bincount(labels.flatten(), minlength=k)
    dominant_idx = int(np.argmax(counts))
    dominant_center = centers[dominant_idx]
    dominant_ratio = counts[dominant_idx] / len(pixels)

    color_dists: Dict[str, float] = {}
    for name, (h, s, v) in NAMED_COLORS_HSV.items():
        ref = np.array([h, s, v], dtype=np.float32)
        # Hue wraps at 180 — use the circular distance.
        h_diff = min(abs(dominant_center[0] - ref[0]),
                     180 - abs(dominant_center[0] - ref[0]))
        dist = np.sqrt((h_diff * 2) ** 2
                       + (dominant_center[1] - ref[1]) ** 2
                       + (dominant_center[2] - ref[2]) ** 2)
        color_dists[name] = float(dist)

    max_dist = 400.0
    color_confs = {
        name: round(max(0.0, 1.0 - d / max_dist), 3)
        for name, d in color_dists.items()
    }

    best_color = min(color_dists, key=color_dists.get)
    best_conf = color_confs[best_color] * min(dominant_ratio * 2, 1.0)
    return best_color, round(best_conf, 3), color_confs


# ---------------------------------------------------------------------------
# Shape / feedback helpers
# ---------------------------------------------------------------------------

def _shapes_match(detected: str, target: str) -> bool:
    if detected == target:
        return True
    return target in SHAPE_ALIASES.get(detected, [])


def _generate_feedback(
    detected_shape: str,
    detected_color: str,
    target_shape: str,
    target_color: str,
    is_correct: bool,
    coverage: float,
    has_enough_coverage: bool,
    require_fill: bool,
    is_scribble: bool,
    is_too_small_flag: bool,
    shape_confidence: float,
) -> Tuple[str, str]:
    if is_scribble:
        return (f"That looks like a scribble! Try drawing a clear "
                f"{target_color} {target_shape}.", "encouraging")

    if is_too_small_flag:
        return ("Your drawing is very small! Try drawing bigger so "
                "I can see it clearly.", "encouraging")

    if detected_shape == "other" or shape_confidence < 0.45:
        return (f"Hmm, I'm not sure what that is. Try drawing a clear "
                f"{target_color} {target_shape}!", "encouraging")

    if is_correct:
        return (f"Amazing! You drew a perfect {target_color} {target_shape}!",
                "happy")

    shape_ok = _shapes_match(detected_shape, target_shape)
    color_ok = detected_color == target_color

    if require_fill and shape_ok and color_ok and not has_enough_coverage:
        pct = int(coverage * 100)
        return (f"Good start! I can see a {target_color} {target_shape}, "
                f"but only {pct}% is filled. Color more!", "encouraging")

    hints = {
        "triangle":  "Remember, a triangle has 3 corners!",
        "square":    "A square has 4 equal sides!",
        "rectangle": "A rectangle has 4 sides — two long, two short!",
        "circle":    "Try to make it round — no corners!",
        "ellipse":   "An ellipse is an oval — try a stretched circle!",
    }

    if not shape_ok and not color_ok:
        return (f"Hmm, I see a {detected_color} {detected_shape}. "
                f"Let's try a {target_color} {target_shape}!", "encouraging")
    if not shape_ok:
        hint = hints.get(target_shape, f"Try drawing a {target_shape}!")
        return (f"Great {detected_color} color! But I see a "
                f"{detected_shape}. {hint}", "encouraging")
    return (f"Nice {detected_shape}! But can you make it {target_color}? "
            "Look at the color palette!", "hint_color")


# ---------------------------------------------------------------------------
# Main service
# ---------------------------------------------------------------------------

class DrawingService:
    """CNN-based shape analysis + K-means HSV color detection."""

    def __init__(self) -> None:
        self.model = HDSShapeModel(settings.MODEL_PATH_HDS_SHAPE)
        self.model.load()
        if not self.model.is_loaded:
            print("[DrawingService] WARNING: HDS shape model is NOT loaded. "
                  "Calls to /drawing/analyze will fail. Run "
                  "`python -m ml.training.train_hds` to produce weights.")

    # ------------------------------------------------------------------

    def analyze_drawing(
        self,
        image_bytes: bytes,
        target_shape: str = "triangle",
        target_color: str = "blue",
        require_fill: bool = False,
    ) -> DrawingAnalysisResponse:
        target_shape = target_shape.lower()
        target_color = target_color.lower()

        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if image is None:
                return _error("Could not read the image. Try again!")

            # 1) Stroke mask (for color + scribble checks).
            gray_norm, _ = _background_corrected_gray(image)
            mask = _stroke_mask(gray_norm)

            if cv2.countNonZero(mask) == 0:
                return _error("I don't see a drawing yet! "
                              "Draw something and try again!")

            # 2) Main contour → scribble / too-small flags.
            contour = _largest_external_contour(mask)
            if contour is None:
                return _error("I don't see a drawing yet! "
                              "Draw something and try again!")

            scribble = _is_scribble(contour)
            too_small = _is_too_small(contour, image.shape)

            # 3) Shape classification via CNN.
            if not self.model.is_loaded:
                return _error("Drawing model is not available right now. "
                              "Please try again later.")

            # Crop the original image to the main contour's bounding box with
            # ~15% padding. This isolates the intended shape from stray strokes
            # and matches the HDS convention of a centered shape with margin.
            shape_input = _crop_to_contour_bbox(image, contour, margin=0.15)

            try:
                shape_result = self.model.predict(shape_input)
            except Exception as e:
                print(f"[DrawingService] CNN prediction failed: {e}")
                return _error("Oops! I couldn't analyze the drawing. "
                              "Try again!")

            detected_shape: str = shape_result["shape"]
            raw_shape: str = shape_result["raw_shape"]
            conf_shape: float = float(shape_result["confidence"])

            # Build a game-facing confidence dict. Map HDS probabilities onto
            # the refined game labels. We keep the rectangle probability in
            # BOTH rectangle/square buckets (not zero-ing one out) so debug
            # clients can see the raw model distribution.
            raw_probs: Dict[str, float] = {
                k: round(float(v), 4)
                for k, v in shape_result["probabilities"].items()
            }
            rect_prob = raw_probs.get("rectangle", 0.0)
            ell_prob = raw_probs.get("ellipse", 0.0)
            shape_confs: Dict[str, float] = {
                "triangle":  raw_probs.get("triangle", 0.0),
                "square":    rect_prob,
                "rectangle": rect_prob,
                "circle":    ell_prob,
                "ellipse":   ell_prob,
            }
            shape_confs = {k: round(float(v), 3) for k, v in shape_confs.items()}

            # 4) Color detection (K-means on HSV inside stroke mask).
            detected_color, conf_color, color_confs = _detect_color_kmeans(
                image, mask)

            # 5) Coverage (only enforced when require_fill=True).
            coverage = _coverage(mask)
            has_enough = coverage >= MIN_COVERAGE_FILL if require_fill else True

            # 6) Final decision.
            shape_matches = _shapes_match(detected_shape, target_shape)
            color_matches = detected_color == target_color
            is_correct = bool(
                shape_matches and color_matches and has_enough
                and not scribble and not too_small
                and detected_shape != "other"
            )

            # 7) User-friendly message.
            message, emotion = _generate_feedback(
                detected_shape, detected_color,
                target_shape, target_color,
                is_correct, coverage, has_enough,
                require_fill, scribble, too_small,
                conf_shape,
            )

            return DrawingAnalysisResponse(
                detected_shape=detected_shape,
                detected_color=detected_color,
                vertex_count=0,  # legacy field, not used by the CNN pipeline
                is_triangle=(detected_shape == "triangle"),
                is_blue=(detected_color == "blue"),
                is_circle=(detected_shape == "circle"),
                is_red=(detected_color == "red"),
                is_correct=is_correct,
                confidence_shape=round(conf_shape, 3),
                confidence_color=round(conf_color, 3),
                coverage=round(coverage, 3),
                shape_confidences=shape_confs,
                raw_probabilities=raw_probs,
                color_confidences=color_confs,
                is_scribble=scribble,
                is_too_small=too_small,
                message=message,
                pixy_emotion=emotion,
            )

        except Exception as e:
            print(f"[DrawingService] Unexpected failure: {e}")
            import traceback
            traceback.print_exc()
            return _error("Oops! Something went wrong. Try again!")


def _error(msg: str) -> DrawingAnalysisResponse:
    return DrawingAnalysisResponse(message=msg, pixy_emotion="encouraging")


drawing_service = DrawingService()
