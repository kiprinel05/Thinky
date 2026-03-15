"""
Drawing analysis service - robust shape and color detection.

Supports: triangle, square, rectangle, circle, star, diamond, pentagon, hexagon.
Handles: faint drawings, multiple strokes, adaptive thresholding, flexible matching.
"""
import cv2
import numpy as np
from typing import Tuple, Optional, List, Dict

from features.drawing.schemas import DrawingAnalysisResponse


# Shapes that can be considered equivalent for matching (e.g. rectangle ≈ square)
# When detected=X, we accept target if target in aliases[X]
SHAPE_ALIASES = {
    "rectangle": ["square", "circle"],  # Round rect ≈ circle
    "square": ["rectangle", "circle"],  # Round square ≈ circle (coloring mission)
    "diamond": ["square"],  # Diamond is a rotated square
}


class DrawingService:
    """
    Robust drawing analysis using OpenCV.
    - Multiple shapes: triangle, square, circle, star, diamond, pentagon, hexagon
    - Adaptive preprocessing for faint/rough drawings
    - Convex hull for scattered strokes
    - Flexible shape matching (rectangle→square, etc.)
    """

    # HSV ranges - tuned for Flutter ColorPalette.defaultColors
    # Blue 0xFF2196F3, Red 0xFFF44336, Green 0xFF4CAF50, Yellow 0xFFFFEB3B,
    # Purple 0xFF9C27B0, Orange 0xFFFF9800, Black 0xFF000000
    COLOR_RANGES = {
        "blue": {"lower": np.array([95, 40, 40]), "upper": np.array([135, 255, 255])},
        "red_low": {"lower": np.array([0, 40, 40]), "upper": np.array([10, 255, 255])},
        "red_high": {"lower": np.array([165, 40, 40]), "upper": np.array([180, 255, 255])},
        "green": {"lower": np.array([35, 40, 40]), "upper": np.array([90, 255, 255])},
        "yellow": {"lower": np.array([18, 40, 40]), "upper": np.array([38, 255, 255])},
        "purple": {"lower": np.array([125, 40, 40]), "upper": np.array([165, 255, 255])},
        "orange": {"lower": np.array([8, 40, 40]), "upper": np.array([25, 255, 255])},
        "black": {"lower": np.array([0, 0, 0]), "upper": np.array([180, 255, 50])},
    }

    SUPPORTED_SHAPES = [
        "triangle", "square", "rectangle", "circle", "star",
        "diamond", "pentagon", "hexagon"
    ]

    MIN_COVERAGE = 0.08  # 8% - slightly more lenient for kids
    MIN_CONTOUR_AREA = 300  # Ignore tiny noise
    MIN_CANVAS_RATIO = 0.02  # Drawing should be at least 2% of canvas

    def __init__(self):
        pass

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
                return self._error_response("Could not read the image. Try again!")

            # Preprocess - get best binary image
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            thresh = self._preprocess_image(gray)

            # Get main contour (possibly merged from multiple strokes)
            main_contour = self._get_main_contour(thresh, image.shape)
            if main_contour is None:
                return self._error_response(
                    "I don't see a drawing yet! Draw something and try again. 🎨"
                )

            # Detect shape with multiple epsilon attempts
            shape_result = self._detect_shape_robust(main_contour)
            detected_shape = shape_result["shape"]
            confidence_shape = shape_result["confidence"]

            # Detect color
            color_result = self._detect_dominant_color(image, thresh)
            detected_color = color_result["color"]
            confidence_color = color_result["confidence"]

            # Coverage - only required when require_fill=True
            coverage = self._calculate_coverage(thresh)
            has_enough_coverage = coverage >= self.MIN_COVERAGE if require_fill else True

            # Flexible shape matching (rectangle→square, etc.)
            shape_matches = self._shapes_match(detected_shape, target_shape)
            color_matches = detected_color == target_color
            is_correct = shape_matches and color_matches and has_enough_coverage

            message, pixy_emotion = self._generate_feedback(
                detected_shape, detected_color,
                target_shape, target_color,
                is_correct, coverage, has_enough_coverage,
                require_fill=require_fill,
            )

            return DrawingAnalysisResponse(
                detected_shape=detected_shape,
                detected_color=detected_color,
                vertex_count=shape_result.get("vertices", 0),
                is_triangle=(detected_shape == "triangle"),
                is_blue=(detected_color == "blue"),
                is_circle=(detected_shape == "circle"),
                is_red=(detected_color == "red"),
                is_correct=is_correct,
                confidence_shape=confidence_shape,
                confidence_color=confidence_color,
                coverage=round(coverage, 2),
                message=message,
                pixy_emotion=pixy_emotion,
            )

        except Exception as e:
            print(f"[ERROR] Drawing analysis failed: {e}")
            import traceback
            traceback.print_exc()
            return self._error_response("Oops! Something went wrong. Try again!")

    def _error_response(self, message: str) -> DrawingAnalysisResponse:
        return DrawingAnalysisResponse(
            message=message,
            pixy_emotion="encouraging",
        )

    def _preprocess_image(self, gray: np.ndarray) -> np.ndarray:
        """Get binary image - try multiple methods, pick best."""
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # Method 1: Otsu inverted (dark strokes on light bg)
        _, thresh_inv = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        # Method 2: Otsu normal (light strokes on dark - rare)
        _, thresh_norm = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        # Pick the one with more "drawing" pixels (typically 10-60% of canvas)
        h, w = gray.shape
        total = h * w
        inv_pixels = cv2.countNonZero(thresh_inv)
        norm_pixels = cv2.countNonZero(thresh_norm)

        inv_ratio = inv_pixels / total if total > 0 else 0
        norm_ratio = norm_pixels / total if total > 0 else 0

        # Prefer inverted if it looks like a drawing (5-70% filled)
        if 0.05 <= inv_ratio <= 0.75:
            return thresh_inv
        if 0.05 <= norm_ratio <= 0.75:
            return thresh_norm

        # Fallback: adaptive threshold for uneven lighting
        adaptive = cv2.adaptiveThreshold(
            blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV, 11, 2
        )
        return adaptive

    def _get_main_contour(self, thresh: np.ndarray, img_shape: tuple) -> Optional[np.ndarray]:
        """Get main drawing contour, possibly merging multiple strokes via convex hull."""
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if not contours:
            return None

        # Filter by area
        valid = [c for c in contours if cv2.contourArea(c) >= self.MIN_CONTOUR_AREA]
        if not valid:
            return None

        # If one dominant contour, use it
        largest = max(valid, key=cv2.contourArea)
        area = cv2.contourArea(largest)
        total_pixels = img_shape[0] * img_shape[1]
        if area / total_pixels < self.MIN_CANVAS_RATIO:
            return None

        # If multiple significant contours (e.g. triangle drawn with 3 lines), use convex hull
        if len(valid) > 1:
            combined = np.vstack(valid)
            hull = cv2.convexHull(combined)
            if cv2.contourArea(hull) >= self.MIN_CONTOUR_AREA:
                return hull

        return largest

    def _detect_shape_robust(self, contour: np.ndarray) -> dict:
        """Detect shape trying multiple approximation tolerances."""
        best = {"shape": "unknown", "vertices": 0, "confidence": 0.0}

        for eps_factor in [0.01, 0.02, 0.04, 0.06, 0.08, 0.10]:
            peri = cv2.arcLength(contour, True)
            if peri < 1:
                continue
            epsilon = eps_factor * peri
            approx = cv2.approxPolyDP(contour, epsilon, True)
            vertices = len(approx)

            shape, confidence = self._classify_shape(contour, approx, vertices)
            if confidence > best["confidence"]:
                best = {"shape": shape, "vertices": vertices, "confidence": confidence}

        return best

    def _classify_shape(
        self, contour: np.ndarray, approx: np.ndarray, vertices: int
    ) -> Tuple[str, float]:
        """Classify shape from vertex count and geometry."""
        area = cv2.contourArea(contour)
        perimeter = cv2.arcLength(contour, True)
        if perimeter < 1:
            return "unknown", 0.0

        circularity = 4 * np.pi * area / (perimeter ** 2)

        if vertices == 3:
            conf = self._triangle_confidence(contour)
            return "triangle", conf

        if vertices == 4:
            # High circularity = round shape (circle) despite 4-vertex approximation
            if circularity > 0.80:
                return "circle", min(circularity, 1.0)
            shape, conf = self._classify_quadrilateral(approx)
            return shape, conf

        if vertices == 5:
            # Pentagon or star (5-pointed star has 10 vertices, but kids may draw 5)
            if circularity > 0.85:
                return "circle", min(circularity, 1.0)
            return "pentagon", 0.6

        if vertices == 6:
            if circularity > 0.88:
                return "circle", min(circularity, 1.0)
            return "hexagon", 0.6

        if vertices == 10:
            return "star", 0.7

        if vertices >= 7:
            # Many vertices → circle
            return "circle", min(circularity, 1.0)

        return "unknown", 0.0

    def _triangle_confidence(self, contour: np.ndarray) -> float:
        area = cv2.contourArea(contour)
        perimeter = cv2.arcLength(contour, True)
        if perimeter < 1:
            return 0.0
        compactness = 4 * np.pi * area / (perimeter ** 2)
        ideal = 0.6
        conf = 1 - min(abs(compactness - ideal) / ideal, 1.0)
        return round(min(max(conf, 0.0), 1.0), 2)

    def _classify_quadrilateral(self, approx: np.ndarray) -> Tuple[str, float]:
        """Distinguish square, rectangle, diamond."""
        (x, y, w, h) = cv2.boundingRect(approx)
        if w < 2 or h < 2:
            return "square", 0.5
        aspect = float(w) / h

        # Check if diamond (rotated 45°) - corners form a diamond shape
        pts = approx.reshape(4, 2)
        # For diamond, two opposite sides are more "diagonal"
        # Simple heuristic: square has aspect ~1, rectangle is elongated
        if 0.75 <= aspect <= 1.33:
            compactness = 4 * np.pi * cv2.contourArea(approx) / (cv2.arcLength(approx, True) ** 2)
            conf = 1 - min(abs(compactness - 0.785) / 0.785, 1.0)
            return "square", round(min(max(conf, 0.0), 1.0), 2)
        if 0.5 <= aspect <= 2.0:
            return "rectangle", 0.65
        return "square", 0.5

    def _detect_dominant_color(self, image: np.ndarray, drawing_mask: np.ndarray) -> dict:
        """Detect dominant color in drawing pixels."""
        total = cv2.countNonZero(drawing_mask)
        if total == 0:
            return {"color": "unknown", "confidence": 0.0}

        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        color_scores: Dict[str, float] = {}

        for name, ranges in self.COLOR_RANGES.items():
            if name.startswith("red_"):
                continue
            mask = cv2.inRange(hsv, ranges["lower"], ranges["upper"])
            combined = cv2.bitwise_and(mask, drawing_mask)
            count = cv2.countNonZero(combined)
            color_scores[name] = count / total if total > 0 else 0

        # Red wraps in HSV
        rl = self.COLOR_RANGES["red_low"]
        rh = self.COLOR_RANGES["red_high"]
        red_mask = cv2.bitwise_or(
            cv2.inRange(hsv, rl["lower"], rl["upper"]),
            cv2.inRange(hsv, rh["lower"], rh["upper"]),
        )
        color_scores["red"] = cv2.countNonZero(cv2.bitwise_and(red_mask, drawing_mask)) / total

        dominant = max(color_scores, key=color_scores.get)
        conf = color_scores[dominant]
        if conf < 0.08:
            return {"color": "unknown", "confidence": round(conf, 2)}
        return {"color": dominant, "confidence": round(conf, 2)}

    def _calculate_coverage(self, thresh: np.ndarray) -> float:
        total = thresh.shape[0] * thresh.shape[1]
        drawn = cv2.countNonZero(thresh)
        return drawn / total if total > 0 else 0.0

    def _shapes_match(self, detected: str, target: str) -> bool:
        """Flexible matching: rectangle→square, diamond→square, etc."""
        if detected == target:
            return True
        aliases = SHAPE_ALIASES.get(detected, [])
        return target in aliases

    def _generate_feedback(
        self,
        detected_shape: str,
        detected_color: str,
        target_shape: str,
        target_color: str,
        is_correct: bool,
        coverage: float,
        has_enough_coverage: bool,
        require_fill: bool = False,
    ) -> Tuple[str, str]:
        if is_correct:
            return (
                f"Amazing! You drew a perfect {target_color} {target_shape}! 🎉",
                "happy",
            )

        shape_match = self._shapes_match(detected_shape, target_shape)
        color_match = detected_color == target_color

        if require_fill and shape_match and color_match and not has_enough_coverage:
            pct = int(coverage * 100)
            return (
                f"Good start! I can see a {target_color} {target_shape}, but draw more! "
                f"Only {pct}% filled. Fill the shape more! 🖍️",
                "encouraging",
            )

        hints = {
            "triangle": "Remember, a triangle has 3 corners!",
            "square": "A square has 4 equal sides!",
            "rectangle": "A rectangle has 4 sides - try making them equal for a square!",
            "circle": "Try to make it round - no corners!",
            "star": "A star has 5 points!",
            "diamond": "A diamond is like a square turned sideways!",
            "pentagon": "A pentagon has 5 sides!",
            "hexagon": "A hexagon has 6 sides!",
        }

        if not shape_match and not color_match:
            return (
                f"Hmm, I see a {detected_color} {detected_shape}. "
                f"Let's try a {target_color} {target_shape}!",
                "encouraging",
            )
        if not shape_match:
            hint = hints.get(target_shape, f"Try drawing a {target_shape}!")
            return (
                f"Great {detected_color} color! But I see a {detected_shape}. {hint}",
                "encouraging",
            )
        return (
            f"Nice {detected_shape}! Can you make it {target_color}? Look at the palette! 🎨",
            "hint_color",
        )


drawing_service = DrawingService()
