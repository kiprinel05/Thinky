import cv2
import numpy as np
from typing import Tuple


class DigitRecognitionService:
    """
    Simplified digit recognition (1-5) using OpenCV contour analysis.
    
    Uses heuristic rules based on:
    - Aspect ratio (height/width)
    - Number of contour endpoints / corners
    - Loop detection (enclosed areas)
    - Stroke direction analysis
    
    This is intentionally simplified for the educational simulation,
    not a production ML model.
    """

    # Heuristic descriptions for each digit (used for professor hints) — bilingual
    DIGIT_HINTS = {
        "ro": {
            1: "Cifra 1 este o linie dreaptă, de sus în jos.",
            2: "Cifra 2 are o curbă sus și o linie orizontală jos.",
            3: "Cifra 3 are două curbe rotunde, una deasupra celeilalte.",
            4: "Cifra 4 are o linie în jos, una orizontală și una verticală.",
            5: "Cifra 5 are o linie orizontală sus, o curbă jos.",
        },
        "en": {
            1: "The digit 1 is a straight line, from top to bottom.",
            2: "The digit 2 has a curve on top and a horizontal line at the bottom.",
            3: "The digit 3 has two round curves, one above the other.",
            4: "The digit 4 has a vertical line down, a horizontal one, and another vertical one.",
            5: "The digit 5 has a horizontal line on top and a curve at the bottom.",
        },
    }

    DIGIT_HINT_FALLBACK = {
        "ro": "Încearcă să desenezi cifra clar.",
        "en": "Try to draw the digit clearly.",
    }

    def __init__(self):
        pass

    def recognize(self, image_bytes: bytes, model_level: str = "junior") -> Tuple[int, float]:
        """
        Recognize a digit (1-5) from image bytes.
        
        Args:
            image_bytes: PNG/JPG image as bytes
            model_level: "junior", "student", or "expert" — affects noise level
            
        Returns:
            (guessed_digit, confidence) where digit is 1-5 and confidence is 0.0-1.0
        """
        try:
            # Decode image
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

            if image is None:
                return (1, 0.0)

            # Preprocess: grayscale + binarization
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            blurred = cv2.GaussianBlur(gray, (5, 5), 0)
            _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

            # Find contours
            contours, hierarchy = cv2.findContours(
                binary, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE
            )

            if not contours:
                return (1, 0.0)

            # Get the largest contour (main drawing)
            largest = max(contours, key=cv2.contourArea)
            area = cv2.contourArea(largest)

            if area < 200:
                return (1, 0.0)

            # Analyze features
            features = self._extract_features(largest, contours, hierarchy, binary)
            
            # Classify based on features
            digit, confidence = self._classify_digit(features)

            # Apply model-level noise
            digit, confidence = self._apply_model_noise(digit, confidence, model_level)

            return (digit, confidence)

        except Exception as e:
            print(f"[ERROR] Digit recognition failed: {e}")
            return (1, 0.0)

    def _extract_features(self, largest_contour, all_contours, hierarchy, binary) -> dict:
        """Extract geometric features from the drawing."""
        # Bounding box and aspect ratio
        x, y, w, h = cv2.boundingRect(largest_contour)
        aspect_ratio = h / w if w > 0 else 1.0

        # Contour approximation
        peri = cv2.arcLength(largest_contour, True)
        approx = cv2.approxPolyDP(largest_contour, 0.03 * peri, True)
        vertex_count = len(approx)

        # Solidity (area / convex hull area)
        hull = cv2.convexHull(largest_contour)
        hull_area = cv2.contourArea(hull)
        solidity = cv2.contourArea(largest_contour) / hull_area if hull_area > 0 else 0

        # Count holes (inner contours / loops)
        hole_count = 0
        if hierarchy is not None:
            for i, h in enumerate(hierarchy[0]):
                # h[3] is parent index; if parent is the largest contour index, it's a hole
                if h[3] >= 0:
                    hole_count += 1

        # Extent (area / bounding rect area)
        rect_area = w * h
        extent = cv2.contourArea(largest_contour) / rect_area if rect_area > 0 else 0

        # Check for horizontal lines (top/bottom regions)
        top_region = binary[y:y + h // 4, x:x + w]
        bottom_region = binary[y + 3 * h // 4:y + h, x:x + w]
        top_density = np.sum(top_region > 0) / (top_region.size + 1)
        bottom_density = np.sum(bottom_region > 0) / (bottom_region.size + 1)

        # Check for vertical symmetry
        left_half = binary[y:y + h, x:x + w // 2]
        right_half = binary[y:y + h, x + w // 2:x + w]
        left_density = np.sum(left_half > 0) / (left_half.size + 1)
        right_density = np.sum(right_half > 0) / (right_half.size + 1)

        return {
            "aspect_ratio": aspect_ratio,
            "vertex_count": vertex_count,
            "solidity": solidity,
            "hole_count": hole_count,
            "extent": extent,
            "top_density": top_density,
            "bottom_density": bottom_density,
            "left_density": left_density,
            "right_density": right_density,
            "contour_count": len(all_contours),
        }

    def _classify_digit(self, features: dict) -> Tuple[int, float]:
        """
        Classify digit based on heuristic rules.
        Returns (digit, confidence).
        """
        scores = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0}

        ar = features["aspect_ratio"]
        sol = features["solidity"]
        holes = features["hole_count"]
        ext = features["extent"]
        verts = features["vertex_count"]
        top_d = features["top_density"]
        bottom_d = features["bottom_density"]
        left_d = features["left_density"]
        right_d = features["right_density"]

        # ─── DIGIT 1: tall, thin, no loops ───
        if ar > 2.5:
            scores[1] += 3.0
        elif ar > 1.8:
            scores[1] += 2.0
        if ext < 0.35:
            scores[1] += 1.5
        if holes == 0:
            scores[1] += 1.0
        if verts <= 6:
            scores[1] += 0.5

        # ─── DIGIT 2: moderate AR, curve top + flat bottom ───
        if 1.2 < ar < 2.5:
            scores[2] += 1.5
        if bottom_d > 0.3:
            scores[2] += 2.0
        if top_d > 0.2 and right_d > left_d:
            scores[2] += 1.5
        if holes == 0:
            scores[2] += 0.5
        if sol > 0.4:
            scores[2] += 0.5

        # ─── DIGIT 3: bumpy right side, two arcs ───
        if 1.2 < ar < 2.5:
            scores[3] += 1.0
        if right_d > left_d * 1.3:
            scores[3] += 2.0
        if verts > 6:
            scores[3] += 1.0
        if holes == 0:
            scores[3] += 0.5
        if sol < 0.65:
            scores[3] += 1.0

        # ─── DIGIT 4: junction, mix of vertical/horizontal ───
        if 1.0 < ar < 2.2:
            scores[4] += 1.0
        if left_d > 0.2 and right_d > 0.2:
            scores[4] += 1.0
        if ext > 0.25 and ext < 0.55:
            scores[4] += 1.5
        if 4 <= verts <= 8:
            scores[4] += 1.5
        if holes == 0:
            scores[4] += 0.5

        # ─── DIGIT 5: horizontal top, curve bottom ───
        if 1.0 < ar < 2.2:
            scores[5] += 1.0
        if top_d > 0.35:
            scores[5] += 2.0
        if bottom_d > 0.2 and right_d > left_d:
            scores[5] += 1.5
        if holes == 0:
            scores[5] += 0.5
        if sol > 0.35:
            scores[5] += 0.5

        # Pick the best guess
        best_digit = max(scores, key=scores.get)
        best_score = scores[best_digit]
        total_score = sum(scores.values())
        confidence = best_score / total_score if total_score > 0 else 0.0

        return (best_digit, round(min(confidence, 1.0), 2))

    def _apply_model_noise(
        self, digit: int, confidence: float, model_level: str
    ) -> Tuple[int, float]:
        """
        Apply noise based on model level to simulate different AI capabilities.
        """
        import random

        if model_level == "junior":
            # 40% chance of correct answer
            if random.random() > 0.40:
                # Pick a wrong digit
                wrong_digits = [d for d in range(1, 6) if d != digit]
                digit = random.choice(wrong_digits)
                confidence = round(random.uniform(0.15, 0.40), 2)
            else:
                confidence = round(min(confidence * 0.6, 0.50), 2)

        elif model_level == "student":
            # 70% chance of correct answer
            if random.random() > 0.70:
                wrong_digits = [d for d in range(1, 6) if d != digit]
                digit = random.choice(wrong_digits)
                confidence = round(random.uniform(0.30, 0.55), 2)
            else:
                confidence = round(min(confidence * 0.85, 0.75), 2)

        else:  # expert
            # 95% chance of correct answer
            if random.random() > 0.95:
                wrong_digits = [d for d in range(1, 6) if d != digit]
                digit = random.choice(wrong_digits)
                confidence = round(random.uniform(0.50, 0.70), 2)
            else:
                confidence = round(min(confidence * 1.0, 0.95), 2)

        return (digit, confidence)

    def get_hint(self, digit: int, lang: str = "en") -> str:
        """Get a professor hint for how to draw a digit, in the requested language."""
        code = (lang or "en").strip().lower()[:2]
        if code not in ("en", "ro"):
            code = "en"
        hints = self.DIGIT_HINTS.get(code, self.DIGIT_HINTS["en"])
        return hints.get(digit, self.DIGIT_HINT_FALLBACK.get(code, self.DIGIT_HINT_FALLBACK["en"]))


# Singleton
digit_recognition_service = DigitRecognitionService()
