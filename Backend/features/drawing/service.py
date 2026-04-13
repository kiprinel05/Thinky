"""
Drawing analysis service — multi-strategy shape classifier with advanced OpenCV.

Pipeline:
  1. Background normalization (dark mode safe)
  2. Adaptive preprocessing (morphological ops, multi-threshold)
  3. Contour extraction (merge disconnected strokes)
  4. 4-strategy shape classification with weighted consensus
  5. K-means color detection
  6. Edge case handling (scribbles, too-small, empty)
"""
import cv2
import numpy as np
from typing import Tuple, Optional, Dict, List

from features.drawing.schemas import DrawingAnalysisResponse

SUPPORTED_SHAPES = ["triangle", "square", "rectangle", "circle", "star",
                    "diamond", "pentagon", "hexagon"]

SHAPE_ALIASES = {
    "rectangle": ["square", "circle"],
    "square": ["rectangle", "circle"],
    "diamond": ["square"],
}

# Named colors as HSV centroids (H 0-180, S 0-255, V 0-255)
NAMED_COLORS_HSV = {
    "red":    (  0, 220, 220),
    "orange": ( 15, 220, 230),
    "yellow": ( 28, 200, 240),
    "green":  ( 60, 180, 180),
    "blue":   (110, 200, 220),
    "purple": (140, 180, 180),
    "black":  (  0,   0,  30),
}

# Weights for the 4 shape-classification strategies
W_HU = 0.35
W_CIRC = 0.25
W_FEAT = 0.25
W_FOUR = 0.15

MIN_CONTOUR_AREA = 80
MIN_CANVAS_RATIO = 0.005
MIN_COVERAGE_FILL = 0.08
SCRIBBLE_SOLIDITY_THRESHOLD = 0.25


# ---------------------------------------------------------------------------
# Reference contour generation (for Hu moment matching)
# ---------------------------------------------------------------------------

def _make_reference_contours() -> Dict[str, np.ndarray]:
    """Generate ideal reference contours for each supported shape."""
    refs: Dict[str, np.ndarray] = {}
    sz = 400
    pad = 40

    # Triangle
    img = np.zeros((sz, sz), dtype=np.uint8)
    pts = np.array([[sz // 2, pad], [pad, sz - pad], [sz - pad, sz - pad]], np.int32)
    cv2.fillPoly(img, [pts], 255)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["triangle"] = max(cnts, key=cv2.contourArea)

    # Square
    img = np.zeros((sz, sz), dtype=np.uint8)
    cv2.rectangle(img, (pad, pad), (sz - pad, sz - pad), 255, -1)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["square"] = max(cnts, key=cv2.contourArea)

    # Rectangle
    img = np.zeros((sz, sz), dtype=np.uint8)
    cv2.rectangle(img, (pad, pad + 80), (sz - pad, sz - pad - 80), 255, -1)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["rectangle"] = max(cnts, key=cv2.contourArea)

    # Circle
    img = np.zeros((sz, sz), dtype=np.uint8)
    cv2.circle(img, (sz // 2, sz // 2), sz // 2 - pad, 255, -1)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["circle"] = max(cnts, key=cv2.contourArea)

    # Pentagon
    img = np.zeros((sz, sz), dtype=np.uint8)
    angles = np.linspace(-np.pi / 2, 2 * np.pi - np.pi / 2, 5, endpoint=False)
    r = sz // 2 - pad
    pts = np.array([[int(sz // 2 + r * np.cos(a)), int(sz // 2 + r * np.sin(a))] for a in angles], np.int32)
    cv2.fillPoly(img, [pts], 255)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["pentagon"] = max(cnts, key=cv2.contourArea)

    # Hexagon
    img = np.zeros((sz, sz), dtype=np.uint8)
    angles = np.linspace(0, 2 * np.pi, 6, endpoint=False)
    pts = np.array([[int(sz // 2 + r * np.cos(a)), int(sz // 2 + r * np.sin(a))] for a in angles], np.int32)
    cv2.fillPoly(img, [pts], 255)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["hexagon"] = max(cnts, key=cv2.contourArea)

    # Star (5-pointed)
    img = np.zeros((sz, sz), dtype=np.uint8)
    outer_r = sz // 2 - pad
    inner_r = outer_r * 0.38
    star_pts = []
    for i in range(10):
        angle = np.pi / 2 + i * np.pi / 5
        radius = outer_r if i % 2 == 0 else inner_r
        star_pts.append([int(sz // 2 + radius * np.cos(angle)),
                         int(sz // 2 - radius * np.sin(angle))])
    cv2.fillPoly(img, [np.array(star_pts, np.int32)], 255)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["star"] = max(cnts, key=cv2.contourArea)

    # Diamond
    img = np.zeros((sz, sz), dtype=np.uint8)
    pts = np.array([[sz // 2, pad], [sz - pad, sz // 2],
                     [sz // 2, sz - pad], [pad, sz // 2]], np.int32)
    cv2.fillPoly(img, [pts], 255)
    cnts, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    refs["diamond"] = max(cnts, key=cv2.contourArea)

    return refs


_REF_CONTOURS = _make_reference_contours()


# ---------------------------------------------------------------------------
# Strategy 1 — Hu Moments
# ---------------------------------------------------------------------------

def _hu_moments_scores(contour: np.ndarray) -> Dict[str, float]:
    """Compare contour against every reference via cv2.matchShapes."""
    scores: Dict[str, float] = {}
    for name, ref in _REF_CONTOURS.items():
        dist = cv2.matchShapes(contour, ref, cv2.CONTOURS_MATCH_I2, 0)
        scores[name] = max(0.0, 1.0 - min(dist, 3.0) / 3.0)
    return scores


# ---------------------------------------------------------------------------
# Strategy 2 — Circularity + Vertex analysis
# ---------------------------------------------------------------------------

def _circularity_vertex_scores(contour: np.ndarray) -> Dict[str, float]:
    area = cv2.contourArea(contour)
    peri = cv2.arcLength(contour, True)
    if peri < 1:
        return {s: 0.0 for s in SUPPORTED_SHAPES}

    circ = 4 * np.pi * area / (peri ** 2)

    # Try multiple epsilon values, collect vertex counts
    vertex_counts = []
    for eps in [0.02, 0.03, 0.04, 0.06]:
        approx = cv2.approxPolyDP(contour, eps * peri, True)
        vertex_counts.append(len(approx))
    median_v = int(np.median(vertex_counts))

    scores: Dict[str, float] = {s: 0.0 for s in SUPPORTED_SHAPES}

    # Circle: high circularity
    scores["circle"] = min(circ / 0.88, 1.0) if circ > 0.65 else circ * 0.5

    # Triangle: 3 vertices, circularity ~0.6
    if median_v == 3:
        scores["triangle"] = 0.7 + 0.3 * max(0, 1 - abs(circ - 0.6) / 0.3)
    elif median_v == 4 and circ < 0.75:
        # Could be a rounded triangle — also check hull vertices
        hull = cv2.convexHull(contour)
        hull_peri = cv2.arcLength(hull, True)
        hull_approx = cv2.approxPolyDP(hull, 0.03 * hull_peri, True) if hull_peri > 1 else hull
        if len(hull_approx) == 3:
            scores["triangle"] = 0.65
        else:
            scores["triangle"] = 0.3

    # Square / Rectangle
    if median_v == 4 and circ < 0.88:
        x, y, w, h = cv2.boundingRect(contour)
        aspect = w / max(h, 1)
        if 0.75 <= aspect <= 1.33:
            scores["square"] = 0.6 + 0.4 * max(0, 1 - abs(circ - 0.785) / 0.2)
        else:
            scores["rectangle"] = 0.65

    # Diamond
    if median_v == 4 and circ < 0.82:
        scores["diamond"] = 0.4

    # Pentagon
    if median_v == 5 and circ < 0.88:
        scores["pentagon"] = 0.65

    # Hexagon
    if median_v == 6 and circ < 0.92:
        scores["hexagon"] = 0.6

    # Star
    if 8 <= median_v <= 12:
        hull_area = cv2.contourArea(cv2.convexHull(contour))
        solidity = area / max(hull_area, 1)
        if solidity < 0.65:
            scores["star"] = 0.7

    return scores


# ---------------------------------------------------------------------------
# Strategy 3 — Contour feature fingerprint
# ---------------------------------------------------------------------------

def _contour_feature_scores(contour: np.ndarray) -> Dict[str, float]:
    area = cv2.contourArea(contour)
    peri = cv2.arcLength(contour, True)
    if peri < 1 or area < 1:
        return {s: 0.0 for s in SUPPORTED_SHAPES}

    hull = cv2.convexHull(contour)
    hull_area = cv2.contourArea(hull)
    solidity = area / max(hull_area, 1)

    x, y, w, h = cv2.boundingRect(contour)
    extent = area / max(w * h, 1)
    aspect = w / max(h, 1)
    circ = 4 * np.pi * area / (peri ** 2)

    # Ideal feature fingerprints: (solidity, extent, circularity)
    ideal = {
        "circle":    (1.0,  0.78, 1.0),
        "square":    (1.0,  1.0,  0.785),
        "rectangle": (1.0,  1.0,  0.70),
        "triangle":  (1.0,  0.50, 0.604),
        "pentagon":  (1.0,  0.76, 0.865),
        "hexagon":   (1.0,  0.83, 0.907),
        "diamond":   (1.0,  0.50, 0.785),
        "star":      (0.55, 0.35, 0.30),
    }

    scores: Dict[str, float] = {}
    features = np.array([solidity, extent, circ])
    for name, ref in ideal.items():
        ref_arr = np.array(ref)
        dist = np.linalg.norm(features - ref_arr)
        scores[name] = max(0.0, 1.0 - dist / 1.5)

    return scores


# ---------------------------------------------------------------------------
# Strategy 4 — Fourier descriptors
# ---------------------------------------------------------------------------

def _fourier_descriptor_scores(contour: np.ndarray) -> Dict[str, float]:
    """Low-frequency Fourier descriptors for shape matching."""
    pts = contour.reshape(-1, 2).astype(np.float64)
    if len(pts) < 8:
        return {s: 0.0 for s in SUPPORTED_SHAPES}

    # Resample contour to fixed number of points
    n_pts = 64
    indices = np.linspace(0, len(pts) - 1, n_pts).astype(int)
    resampled = pts[indices]

    # Complex representation
    z = resampled[:, 0] + 1j * resampled[:, 1]
    # Center
    z -= np.mean(z)

    fft = np.fft.fft(z)
    # Normalize by the first non-DC component for scale invariance
    mag = np.abs(fft)
    if mag[1] < 1e-6:
        return {s: 0.0 for s in SUPPORTED_SHAPES}
    descriptor = mag[1:9] / mag[1]

    # Compute descriptors for references
    scores: Dict[str, float] = {}
    for name, ref_cnt in _REF_CONTOURS.items():
        ref_pts = ref_cnt.reshape(-1, 2).astype(np.float64)
        r_idx = np.linspace(0, len(ref_pts) - 1, n_pts).astype(int)
        r_resampled = ref_pts[r_idx]
        r_z = r_resampled[:, 0] + 1j * r_resampled[:, 1]
        r_z -= np.mean(r_z)
        r_fft = np.fft.fft(r_z)
        r_mag = np.abs(r_fft)
        if r_mag[1] < 1e-6:
            scores[name] = 0.0
            continue
        r_desc = r_mag[1:9] / r_mag[1]

        dist = np.linalg.norm(descriptor - r_desc)
        scores[name] = max(0.0, 1.0 - dist / 3.0)

    return scores


# ---------------------------------------------------------------------------
# Weighted consensus
# ---------------------------------------------------------------------------

def _ellipse_circularity(contour: np.ndarray) -> float:
    """Return 0-1 how circular the contour is based on ellipse fitting."""
    if len(contour) < 5:
        return 0.0
    try:
        (_, _), (ma, MA), _ = cv2.fitEllipse(contour)
        if MA < 1:
            return 0.0
        ratio = min(ma, MA) / max(ma, MA)
        area = cv2.contourArea(contour)
        ellipse_area = np.pi * ma * MA / 4
        fill_ratio = area / max(ellipse_area, 1)
        return ratio * min(fill_ratio, 1.0)
    except cv2.error:
        return 0.0


def _hull_vertex_count(contour: np.ndarray) -> int:
    """Approximate vertex count of the convex hull — robust to morphological rounding."""
    hull = cv2.convexHull(contour)
    peri = cv2.arcLength(hull, True)
    if peri < 1:
        return 0
    counts = []
    for eps in [0.02, 0.03, 0.04]:
        approx = cv2.approxPolyDP(hull, eps * peri, True)
        counts.append(len(approx))
    return int(np.median(counts))


def _consensus(
    hu: Dict[str, float],
    circ: Dict[str, float],
    feat: Dict[str, float],
    four: Dict[str, float],
    contour: np.ndarray,
) -> Dict[str, float]:
    all_shapes = set(hu) | set(circ) | set(feat) | set(four)
    combined: Dict[str, float] = {}
    for s in all_shapes:
        combined[s] = (
            W_HU * hu.get(s, 0) +
            W_CIRC * circ.get(s, 0) +
            W_FEAT * feat.get(s, 0) +
            W_FOUR * four.get(s, 0)
        )

    # Ellipse-based circle boost
    ec = _ellipse_circularity(contour)
    if ec > 0.70:
        combined["circle"] = max(combined.get("circle", 0),
                                 0.45 + ec * 0.45)

    # Hull-based triangle boost: convex hull of a triangle approximates to
    # 3 vertices even when morphological ops round the raw contour.
    hull_v = _hull_vertex_count(contour)
    if hull_v == 3:
        hull = cv2.convexHull(contour)
        hull_peri = cv2.arcLength(hull, True)
        hull_area = cv2.contourArea(hull)
        hull_circ = 4 * np.pi * hull_area / (hull_peri ** 2) if hull_peri > 1 else 0
        if hull_circ < 0.82:
            combined["triangle"] = max(combined.get("triangle", 0), 0.80)

    return combined


# ---------------------------------------------------------------------------
# Background normalizer
# ---------------------------------------------------------------------------

def _normalize_background(image: np.ndarray) -> Tuple[np.ndarray, bool]:
    """
    Detect background brightness from corner samples.
    If dark background, invert so strokes become dark-on-white for shape analysis.
    Returns (normalized_image, was_inverted).
    """
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape
    sample_size = max(5, min(h, w) // 20)

    corners = [
        gray[:sample_size, :sample_size],
        gray[:sample_size, -sample_size:],
        gray[-sample_size:, :sample_size],
        gray[-sample_size:, -sample_size:],
    ]
    bg_brightness = float(np.mean([np.mean(c) for c in corners]))

    inverted = bg_brightness < 128
    if inverted:
        image = cv2.bitwise_not(image)

    return image, inverted


# ---------------------------------------------------------------------------
# Adaptive preprocessor
# ---------------------------------------------------------------------------

def _preprocess(gray: np.ndarray) -> np.ndarray:
    """Multi-strategy thresholding with morphological cleanup."""
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    # Strategy A: Otsu inverted
    _, thresh_inv = cv2.threshold(blurred, 0, 255,
                                  cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    # Strategy B: Adaptive Gaussian
    adaptive = cv2.adaptiveThreshold(blurred, 255,
                                     cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                     cv2.THRESH_BINARY_INV, 15, 4)

    # Pick whichever has a drawing-like fill ratio (1-75%)
    total = gray.shape[0] * gray.shape[1]
    chosen = thresh_inv
    for candidate in [thresh_inv, adaptive]:
        ratio = cv2.countNonZero(candidate) / total
        if 0.01 <= ratio <= 0.75:
            chosen = candidate
            break

    kernel_dilate = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    kernel_close = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11))
    kernel_open = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    cleaned = cv2.dilate(chosen, kernel_dilate, iterations=1)
    cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_CLOSE, kernel_close)
    cleaned = cv2.morphologyEx(cleaned, cv2.MORPH_OPEN, kernel_open)

    return cleaned


# ---------------------------------------------------------------------------
# Contour extraction
# ---------------------------------------------------------------------------

def _smooth_contour(contour: np.ndarray, img_shape: tuple) -> np.ndarray:
    """
    Smooth a contour by drawing it filled on a mask, applying Gaussian blur,
    then re-extracting. Converts polygonal hulls into smoother curves.
    """
    mask = np.zeros(img_shape[:2], dtype=np.uint8)
    cv2.drawContours(mask, [contour], -1, 255, -1)
    mask = cv2.GaussianBlur(mask, (15, 15), 0)
    _, mask = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)
    cnts, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if cnts:
        return max(cnts, key=cv2.contourArea)
    return contour


def _extract_main_contour(
    thresh: np.ndarray, img_shape: tuple
) -> Optional[np.ndarray]:
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL,
                                   cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None

    total_pixels = img_shape[0] * img_shape[1]

    # First try: find large contours
    valid = [c for c in contours if cv2.contourArea(c) >= MIN_CONTOUR_AREA]

    # Fallback: if no large contours, consider ALL contours merged together
    # (handles thin strokes that form a shape from many small segments)
    if not valid and len(contours) >= 3:
        all_pts = np.vstack(contours)
        hull = cv2.convexHull(all_pts)
        if cv2.contourArea(hull) / total_pixels >= MIN_CANVAS_RATIO:
            return _smooth_contour(hull, img_shape)
        return None

    if not valid:
        return None

    largest = max(valid, key=cv2.contourArea)
    if cv2.contourArea(largest) / total_pixels < MIN_CANVAS_RATIO:
        if len(valid) > 1:
            all_pts = np.vstack(valid)
            hull = cv2.convexHull(all_pts)
            if cv2.contourArea(hull) / total_pixels >= MIN_CANVAS_RATIO:
                return _smooth_contour(hull, img_shape)
        return None

    if len(valid) == 1:
        return largest

    # Multiple contours — check if they form one shape (disconnected strokes)
    largest_area = cv2.contourArea(largest)
    combined = np.vstack(valid)
    hull = cv2.convexHull(combined)
    hull_area = cv2.contourArea(hull)

    if hull_area > largest_area * 1.3:
        return _smooth_contour(hull, img_shape)

    return largest


# ---------------------------------------------------------------------------
# K-means color detection
# ---------------------------------------------------------------------------

def _detect_color_kmeans(
    image_bgr: np.ndarray, mask: np.ndarray
) -> Tuple[str, float, Dict[str, float]]:
    """
    K-means on HSV pixels of the drawing region, then map the dominant
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

    # Find the largest cluster
    counts = np.bincount(labels.flatten(), minlength=k)
    dominant_idx = int(np.argmax(counts))
    dominant_center = centers[dominant_idx]
    dominant_ratio = counts[dominant_idx] / len(pixels)

    # Map centroid to nearest named color (weighted HSV distance)
    color_dists: Dict[str, float] = {}
    for name, (h, s, v) in NAMED_COLORS_HSV.items():
        ref = np.array([h, s, v], dtype=np.float32)
        dc = dominant_center.copy()
        # Hue wraps at 180
        h_diff = min(abs(dc[0] - ref[0]), 180 - abs(dc[0] - ref[0]))
        dist = np.sqrt((h_diff * 2) ** 2 + (dc[1] - ref[1]) ** 2 + (dc[2] - ref[2]) ** 2)
        color_dists[name] = float(dist)

    # Convert distances to confidences (inverse)
    max_dist = 400.0
    color_confs: Dict[str, float] = {}
    for name, d in color_dists.items():
        color_confs[name] = round(max(0.0, 1.0 - d / max_dist), 3)

    best_color = min(color_dists, key=color_dists.get)
    best_conf = color_confs[best_color]

    # Low confidence if the dominant cluster is small
    best_conf *= min(dominant_ratio * 2, 1.0)

    return best_color, round(best_conf, 3), color_confs


# ---------------------------------------------------------------------------
# Edge case detectors
# ---------------------------------------------------------------------------

def _is_scribble(contour: np.ndarray) -> bool:
    area = cv2.contourArea(contour)
    hull = cv2.convexHull(contour)
    hull_area = cv2.contourArea(hull)
    if hull_area < 1:
        return True
    solidity = area / hull_area
    return solidity < SCRIBBLE_SOLIDITY_THRESHOLD


def _is_too_small(contour: np.ndarray, img_shape: tuple) -> bool:
    area = cv2.contourArea(contour)
    total = img_shape[0] * img_shape[1]
    return (area / total) < MIN_CANVAS_RATIO


# ---------------------------------------------------------------------------
# Coverage (for coloring missions)
# ---------------------------------------------------------------------------

def _calculate_coverage(thresh: np.ndarray) -> float:
    total = thresh.shape[0] * thresh.shape[1]
    drawn = cv2.countNonZero(thresh)
    return drawn / total if total > 0 else 0.0


# ---------------------------------------------------------------------------
# Flexible shape matching
# ---------------------------------------------------------------------------

def _shapes_match(detected: str, target: str) -> bool:
    if detected == target:
        return True
    return target in SHAPE_ALIASES.get(detected, [])


# ---------------------------------------------------------------------------
# Feedback generator
# ---------------------------------------------------------------------------

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
) -> Tuple[str, str]:
    if is_scribble:
        return ("That looks like a scribble! Try drawing a clear "
                f"{target_color} {target_shape}.", "encouraging")

    if is_too_small_flag:
        return ("Your drawing is very small! Try drawing bigger so "
                "I can see it clearly.", "encouraging")

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
        "triangle": "Remember, a triangle has 3 corners!",
        "square":   "A square has 4 equal sides!",
        "rectangle": "A rectangle has 4 sides!",
        "circle":   "Try to make it round — no corners!",
        "star":     "A star has 5 points!",
        "diamond":  "A diamond is like a square turned sideways!",
        "pentagon": "A pentagon has 5 sides!",
        "hexagon":  "A hexagon has 6 sides!",
    }

    if not shape_ok and not color_ok:
        return (f"Hmm, I see a {detected_color} {detected_shape}. "
                f"Let's try a {target_color} {target_shape}!",
                "encouraging")
    if not shape_ok:
        hint = hints.get(target_shape, f"Try drawing a {target_shape}!")
        return (f"Great {detected_color} color! But I see a "
                f"{detected_shape}. {hint}", "encouraging")

    return (f"Nice {detected_shape}! But can you make it {target_color}? "
            "Look at the color palette!", "hint_color")


# ---------------------------------------------------------------------------
# Main service class
# ---------------------------------------------------------------------------

class DrawingService:
    """
    Robust drawing analysis using a multi-strategy OpenCV pipeline.
    """

    def analyze_drawing(
        self,
        image_bytes: bytes,
        target_shape: str = "triangle",
        target_color: str = "blue",
        require_fill: bool = False,
    ) -> DrawingAnalysisResponse:
        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if image is None:
                return self._error("Could not read the image. Try again!")

            original_image = image.copy()

            # 1. Normalize background (dark-mode safe) — for shape analysis only
            image, was_inverted = _normalize_background(image)
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

            # 2. Adaptive preprocessing
            thresh = _preprocess(gray)

            # 3. Extract main contour
            contour = _extract_main_contour(thresh, image.shape)
            if contour is None:
                return self._error(
                    "I don't see a drawing yet! Draw something and try again!")

            # 4. Edge case checks
            scribble = _is_scribble(contour)
            too_small = _is_too_small(contour, image.shape)

            # 5. Shape classification — 4-strategy consensus
            hu_scores = _hu_moments_scores(contour)
            circ_scores = _circularity_vertex_scores(contour)
            feat_scores = _contour_feature_scores(contour)
            four_scores = _fourier_descriptor_scores(contour)
            shape_confs = _consensus(hu_scores, circ_scores,
                                     feat_scores, four_scores,
                                     contour)

            # Round for readability
            shape_confs = {k: round(v, 3) for k, v in shape_confs.items()}

            detected_shape = max(shape_confs, key=shape_confs.get)
            conf_shape = shape_confs[detected_shape]

            # Vertex count (for legacy frontend fields)
            peri = cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, 0.04 * peri, True) if peri > 0 else contour
            vertex_count = len(approx)

            # 6. Color detection — K-means on the ORIGINAL image (not inverted)
            drawing_mask = np.zeros(gray.shape, dtype=np.uint8)
            cv2.drawContours(drawing_mask, [contour], -1, 255, -1)
            drawing_mask = cv2.bitwise_or(drawing_mask, thresh)
            # Exclude near-white pixels from color sampling (background leakage)
            orig_gray = cv2.cvtColor(original_image, cv2.COLOR_BGR2GRAY)
            white_mask = orig_gray > 235
            drawing_mask[white_mask] = 0

            detected_color, conf_color, color_confs = _detect_color_kmeans(
                original_image, drawing_mask)

            # 7. Coverage
            coverage = _calculate_coverage(thresh)
            has_enough = coverage >= MIN_COVERAGE_FILL if require_fill else True

            # 8. Match check
            shape_matches = _shapes_match(detected_shape, target_shape)
            color_matches = detected_color == target_color
            is_correct = (shape_matches and color_matches
                          and has_enough and not scribble and not too_small)

            # 9. Feedback
            message, emotion = _generate_feedback(
                detected_shape, detected_color,
                target_shape, target_color,
                is_correct, coverage, has_enough,
                require_fill, scribble, too_small,
            )

            return DrawingAnalysisResponse(
                detected_shape=detected_shape,
                detected_color=detected_color,
                vertex_count=vertex_count,
                is_triangle=(detected_shape == "triangle"),
                is_blue=(detected_color == "blue"),
                is_circle=(detected_shape == "circle"),
                is_red=(detected_color == "red"),
                is_correct=is_correct,
                confidence_shape=round(conf_shape, 2),
                confidence_color=round(conf_color, 2),
                coverage=round(coverage, 2),
                shape_confidences=shape_confs,
                color_confidences=color_confs,
                is_scribble=scribble,
                is_too_small=too_small,
                message=message,
                pixy_emotion=emotion,
            )
        except Exception as e:
            print(f"[ERROR] Drawing analysis failed: {e}")
            import traceback
            traceback.print_exc()
            return self._error("Oops! Something went wrong. Try again!")

    @staticmethod
    def _error(msg: str) -> DrawingAnalysisResponse:
        return DrawingAnalysisResponse(message=msg, pixy_emotion="encouraging")


drawing_service = DrawingService()
