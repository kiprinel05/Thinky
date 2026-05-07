import cv2
import numpy as np
from typing import Tuple


class DigitRecognitionService:
    """
    Digit recognition (0-9) using OpenCV contour analysis.

    Uses heuristic rules based on:
    - Aspect ratio (height/width)
    - Number of contour endpoints / corners
    - Loop detection (enclosed areas)
    - Stroke direction analysis
    - Circularity and solidity

    Intentionally simplified for the educational simulation.
    """

    DIGIT_HINTS = {
        0: "Cifra 0 este un oval, ca un ou.",
        1: "Cifra 1 este o linie dreaptă, de sus în jos.",
        2: "Cifra 2 are o curbă sus și o linie orizontală jos.",
        3: "Cifra 3 are două curbe rotunde, una deasupra celeilalte.",
        4: "Cifra 4 are o linie în jos, una orizontală și una verticală.",
        5: "Cifra 5 are o linie orizontală sus, o curbă jos.",
        6: "Cifra 6 are o buclă jos și o curbă sus.",
        7: "Cifra 7 are o linie orizontală sus și o linie diagonală.",
        8: "Cifra 8 are două bucle, una deasupra celeilalte.",
        9: "Cifra 9 are o buclă sus și o linie în jos.",
    }

    def __init__(self):
        pass

    def recognize(self, image_bytes: bytes, model_level: str = "junior") -> Tuple[int, float]:
        """
        Recognize a digit (0-9) from image bytes.

        Returns:
            (guessed_digit, confidence) where digit is 0-9 and confidence is 0.0-1.0
        """
        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            if image is None:
                return (1, 0.1)

            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            binary = self._robust_threshold(gray)

            contours, hierarchy = cv2.findContours(
                binary, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE
            )

            if not contours:
                return (1, 0.1)

            largest = max(contours, key=cv2.contourArea)
            area = cv2.contourArea(largest)

            if area < 100:
                return (1, 0.1)

            features = self._extract_features(largest, contours, hierarchy, binary)
            digit, confidence = self._classify_digit(features)
            digit, confidence = self._apply_model_noise(digit, confidence, model_level)

            return (digit, confidence)

        except Exception as e:
            print(f"[ERROR] Digit recognition failed: {e}")
            return (1, 0.1)

    def _robust_threshold(self, gray: np.ndarray) -> np.ndarray:
        """Try multiple thresholding strategies and pick the best one."""
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        _, thresh_inv = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        adaptive = cv2.adaptiveThreshold(
            blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV, 15, 5
        )

        h, w = gray.shape
        total = h * w
        inv_ratio = cv2.countNonZero(thresh_inv) / total if total > 0 else 0
        ada_ratio = cv2.countNonZero(adaptive) / total if total > 0 else 0

        if 0.03 <= inv_ratio <= 0.70:
            return thresh_inv
        if 0.03 <= ada_ratio <= 0.70:
            return adaptive
        return thresh_inv

    def _extract_features(self, largest_contour, all_contours, hierarchy, binary) -> dict:
        """Extract geometric features from the drawing."""
        x, y, w, h = cv2.boundingRect(largest_contour)
        aspect_ratio = h / w if w > 0 else 1.0

        peri = cv2.arcLength(largest_contour, True)
        approx = cv2.approxPolyDP(largest_contour, 0.03 * peri, True)
        vertex_count = len(approx)

        hull = cv2.convexHull(largest_contour)
        hull_area = cv2.contourArea(hull)
        contour_area = cv2.contourArea(largest_contour)
        solidity = contour_area / hull_area if hull_area > 0 else 0

        circularity = 4 * np.pi * contour_area / (peri ** 2) if peri > 0 else 0

        hole_count = 0
        if hierarchy is not None:
            for i, h_item in enumerate(hierarchy[0]):
                if h_item[3] >= 0:
                    child_area = cv2.contourArea(all_contours[i]) if i < len(all_contours) else 0
                    if child_area > contour_area * 0.05:
                        hole_count += 1

        rect_area = w * h
        extent = contour_area / rect_area if rect_area > 0 else 0

        top_region = binary[y:y + h // 4, x:x + w] if h > 4 else binary[y:y+1, x:x+w]
        bottom_region = binary[y + 3 * h // 4:y + h, x:x + w] if h > 4 else binary[y:y+1, x:x+w]
        mid_region = binary[y + h // 3:y + 2 * h // 3, x:x + w] if h > 3 else binary[y:y+1, x:x+w]
        top_density = np.sum(top_region > 0) / (top_region.size + 1)
        bottom_density = np.sum(bottom_region > 0) / (bottom_region.size + 1)
        mid_density = np.sum(mid_region > 0) / (mid_region.size + 1)

        left_half = binary[y:y + h, x:x + w // 2] if w > 2 else binary[y:y+h, x:x+1]
        right_half = binary[y:y + h, x + w // 2:x + w] if w > 2 else binary[y:y+h, x:x+1]
        left_density = np.sum(left_half > 0) / (left_half.size + 1)
        right_density = np.sum(right_half > 0) / (right_half.size + 1)

        top_half = binary[y:y + h // 2, x:x + w] if h > 2 else binary[y:y+1, x:x+w]
        bottom_half = binary[y + h // 2:y + h, x:x + w] if h > 2 else binary[y:y+1, x:x+w]
        top_half_density = np.sum(top_half > 0) / (top_half.size + 1)
        bottom_half_density = np.sum(bottom_half > 0) / (bottom_half.size + 1)

        return {
            "aspect_ratio": aspect_ratio,
            "vertex_count": vertex_count,
            "solidity": solidity,
            "circularity": circularity,
            "hole_count": hole_count,
            "extent": extent,
            "top_density": top_density,
            "bottom_density": bottom_density,
            "mid_density": mid_density,
            "left_density": left_density,
            "right_density": right_density,
            "top_half_density": top_half_density,
            "bottom_half_density": bottom_half_density,
            "contour_count": len(all_contours),
            "width": w,
            "height": h,
        }

    def _classify_digit(self, features: dict) -> Tuple[int, float]:
        """Classify digit based on heuristic rules. Returns (digit, confidence)."""
        scores = {d: 0.0 for d in range(10)}

        ar = features["aspect_ratio"]
        sol = features["solidity"]
        circ = features["circularity"]
        holes = features["hole_count"]
        ext = features["extent"]
        verts = features["vertex_count"]
        top_d = features["top_density"]
        bottom_d = features["bottom_density"]
        mid_d = features["mid_density"]
        left_d = features["left_density"]
        right_d = features["right_density"]
        top_h = features["top_half_density"]
        bottom_h = features["bottom_half_density"]

        # ─── DIGIT 0: oval/circular, one hole, high circularity ───
        if holes >= 1:
            scores[0] += 2.5
        if circ > 0.6:
            scores[0] += 2.0
        if 0.8 < ar < 1.8:
            scores[0] += 1.5
        if sol > 0.8:
            scores[0] += 1.0
        if ext > 0.5:
            scores[0] += 0.5

        # ─── DIGIT 1: tall, thin, no loops ───
        if ar > 2.5:
            scores[1] += 3.0
        elif ar > 1.8:
            scores[1] += 2.0
        if ext < 0.35:
            scores[1] += 2.0
        elif ext < 0.45:
            scores[1] += 1.0
        if holes == 0:
            scores[1] += 1.0
        if verts <= 6:
            scores[1] += 0.5
        if abs(left_d - right_d) < 0.15:
            scores[1] += 0.5

        # ─── DIGIT 2: curve top, flat bottom line ───
        if 1.0 < ar < 2.5:
            scores[2] += 1.0
        if bottom_d > 0.35:
            scores[2] += 2.5
        if top_d > 0.15 and top_d < bottom_d:
            scores[2] += 1.5
        if holes == 0:
            scores[2] += 1.0
        if sol > 0.35:
            scores[2] += 0.5

        # ─── DIGIT 3: two bumps on right, open left ───
        if 1.0 < ar < 2.5:
            scores[3] += 1.0
        if right_d > left_d * 1.2:
            scores[3] += 2.5
        if mid_d < top_d and mid_d < bottom_d:
            scores[3] += 1.5
        if holes == 0:
            scores[3] += 0.5
        if verts > 5:
            scores[3] += 0.5
        if sol < 0.65:
            scores[3] += 0.5

        # ─── DIGIT 4: angular, crossing lines ───
        if 1.0 < ar < 2.5:
            scores[4] += 1.0
        if holes == 0 or holes == 1:
            scores[4] += 0.5
        if 0.25 < ext < 0.55:
            scores[4] += 1.5
        if 4 <= verts <= 10:
            scores[4] += 1.5
        if right_d > 0.2:
            scores[4] += 1.0
        if top_h > bottom_h * 0.8:
            scores[4] += 0.5

        # ─── DIGIT 5: horizontal top, curve bottom-right ───
        if 1.0 < ar < 2.2:
            scores[5] += 1.0
        if top_d > 0.35:
            scores[5] += 2.5
        if bottom_d > 0.2:
            scores[5] += 1.0
        if left_d > right_d * 0.8:
            scores[5] += 0.5
        if holes == 0:
            scores[5] += 0.5
        if sol > 0.35:
            scores[5] += 0.5

        # ─── DIGIT 6: loop at bottom, curve at top ───
        if 1.0 < ar < 2.2:
            scores[6] += 1.0
        if holes >= 1:
            scores[6] += 2.0
        if bottom_h > top_h * 1.2:
            scores[6] += 2.0
        if left_d > right_d * 0.9:
            scores[6] += 0.5
        if sol > 0.4:
            scores[6] += 0.5

        # ─── DIGIT 7: horizontal top, diagonal line ───
        if ar > 1.5:
            scores[7] += 1.0
        if top_d > 0.4:
            scores[7] += 2.5
        if bottom_d < 0.2:
            scores[7] += 1.5
        if holes == 0:
            scores[7] += 1.0
        if ext < 0.4:
            scores[7] += 1.0
        if right_d > left_d:
            scores[7] += 0.5

        # ─── DIGIT 8: two loops (top and bottom) ───
        if holes >= 2:
            scores[8] += 3.0
        elif holes >= 1:
            scores[8] += 1.0
        if 1.0 < ar < 2.0:
            scores[8] += 1.0
        if abs(top_h - bottom_h) < 0.15:
            scores[8] += 1.5
        if sol > 0.5:
            scores[8] += 0.5
        if circ > 0.4:
            scores[8] += 0.5

        # ─── DIGIT 9: loop at top, line/curve at bottom ───
        if 1.0 < ar < 2.5:
            scores[9] += 1.0
        if holes >= 1:
            scores[9] += 2.0
        if top_h > bottom_h * 1.2:
            scores[9] += 2.0
        if right_d > left_d * 0.9:
            scores[9] += 0.5
        if sol > 0.4:
            scores[9] += 0.5

        best_digit = max(scores, key=scores.get)
        best_score = scores[best_digit]
        total_score = sum(scores.values())
        confidence = best_score / total_score if total_score > 0 else 0.1

        return (best_digit, round(min(confidence, 1.0), 2))

    def _apply_model_noise(
        self, digit: int, confidence: float, model_level: str
    ) -> Tuple[int, float]:
        """Apply noise based on model level to simulate different AI capabilities."""
        import random

        valid_range = list(range(0, 10))

        if model_level == "junior":
            if random.random() > 0.40:
                wrong_digits = [d for d in valid_range if d != digit]
                digit = random.choice(wrong_digits)
                confidence = round(random.uniform(0.15, 0.40), 2)
            else:
                confidence = round(min(confidence * 0.6, 0.50), 2)

        elif model_level == "student":
            if random.random() > 0.70:
                wrong_digits = [d for d in valid_range if d != digit]
                digit = random.choice(wrong_digits)
                confidence = round(random.uniform(0.30, 0.55), 2)
            else:
                confidence = round(min(confidence * 0.85, 0.75), 2)

        else:  # expert
            if random.random() > 0.95:
                wrong_digits = [d for d in valid_range if d != digit]
                digit = random.choice(wrong_digits)
                confidence = round(random.uniform(0.50, 0.70), 2)
            else:
                confidence = round(min(confidence * 1.0, 0.95), 2)

        return (digit, confidence)

    def get_hint(self, digit: int) -> str:
        """Get a professor hint for how to draw a digit."""
        return self.DIGIT_HINTS.get(digit, "Încearcă să desenezi cifra clar.")


# Singleton
digit_recognition_service = DigitRecognitionService()
