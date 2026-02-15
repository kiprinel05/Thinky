import cv2
import numpy as np
from typing import Tuple, Optional
import io

from features.drawing.schemas import DrawingAnalysisResponse


class DrawingService:
    """
    Service for analyzing user drawings using OpenCV.
    Detects shapes (triangle, square, circle) and colors.
    Requires minimum 10% canvas coverage to pass.
    """
    
    # HSV color ranges for detection
    COLOR_RANGES = {
        "blue": {
            "lower": np.array([100, 50, 50]),
            "upper": np.array([130, 255, 255])
        },
        "red_low": {
            "lower": np.array([0, 50, 50]),
            "upper": np.array([10, 255, 255])
        },
        "red_high": {
            "lower": np.array([170, 50, 50]),
            "upper": np.array([180, 255, 255])
        },
        "green": {
            "lower": np.array([35, 50, 50]),
            "upper": np.array([85, 255, 255])
        },
        "yellow": {
            "lower": np.array([20, 50, 50]),
            "upper": np.array([35, 255, 255])
        },
        "purple": {
            "lower": np.array([130, 50, 50]),
            "upper": np.array([160, 255, 255])
        },
        "orange": {
            "lower": np.array([10, 50, 50]),
            "upper": np.array([20, 255, 255])
        }
    }
    
    # Shape names based on vertex count
    SHAPE_NAMES = {
        3: "triangle",
        4: "square",
        5: "pentagon",
        6: "hexagon"
    }
    
    # Minimum coverage required (fraction of canvas that must be drawn on)
    MIN_COVERAGE = 0.10  # 10% of canvas
    
    def __init__(self):
        pass
    
    def analyze_drawing(self, image_bytes: bytes, target_shape: str = "triangle", target_color: str = "blue") -> DrawingAnalysisResponse:
        """
        Analyze a drawing image for shape and color detection.
        
        Args:
            image_bytes: PNG/JPG image as bytes
            target_shape: Expected shape ("triangle", "square", etc.)
            target_color: Expected color ("blue", "red", etc.)
            
        Returns:
            DrawingAnalysisResponse with detection results
        """
        try:
            # Convert bytes to OpenCV image
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if image is None:
                return DrawingAnalysisResponse(
                    message="Could not read the image. Try again!",
                    pixy_emotion="encouraging"
                )
            
            # Detect shape
            shape_result = self._detect_shape(image)
            detected_shape = shape_result["shape"]
            vertex_count = shape_result["vertices"]
            confidence_shape = shape_result["confidence"]
            
            # Detect color
            color_result = self._detect_dominant_color(image)
            detected_color = color_result["color"]
            confidence_color = color_result["confidence"]
            
            # Calculate canvas coverage
            coverage = self._calculate_coverage(image)
            has_enough_coverage = coverage >= self.MIN_COVERAGE
            
            # Check if matches target (shape + color + coverage)
            is_triangle = detected_shape == "triangle"
            is_blue = detected_color == "blue"
            is_circle = detected_shape == "circle"
            is_red = detected_color == "red"
            shape_and_color_match = (detected_shape == target_shape) and (detected_color == target_color)
            is_correct = shape_and_color_match and has_enough_coverage
            
            # Generate feedback message and Pixy emotion
            message, pixy_emotion = self._generate_feedback(
                detected_shape, detected_color,
                target_shape, target_color,
                is_correct, coverage, has_enough_coverage
            )
            
            return DrawingAnalysisResponse(
                detected_shape=detected_shape,
                detected_color=detected_color,
                vertex_count=vertex_count,
                is_triangle=is_triangle,
                is_blue=is_blue,
                is_circle=is_circle,
                is_red=is_red,
                is_correct=is_correct,
                confidence_shape=confidence_shape,
                confidence_color=confidence_color,
                coverage=round(coverage, 2),
                message=message,
                pixy_emotion=pixy_emotion
            )
            
        except Exception as e:
            print(f"[ERROR] Drawing analysis failed: {e}")
            return DrawingAnalysisResponse(
                message="Oops! Something went wrong. Try again!",
                pixy_emotion="encouraging"
            )
    
    def _detect_shape(self, image: np.ndarray) -> dict:
        """
        Detect the shape in the drawing using contour analysis.
        
        Returns dict with shape name, vertex count, and confidence.
        """
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Apply threshold - handle both dark drawings on light bg and vice versa
        _, thresh = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        
        # Find contours
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            return {"shape": "unknown", "vertices": 0, "confidence": 0.0}
        
        # Get the largest contour (main drawing)
        largest_contour = max(contours, key=cv2.contourArea)
        area = cv2.contourArea(largest_contour)
        
        # Filter out very small contours (noise)
        if area < 500:
            return {"shape": "unknown", "vertices": 0, "confidence": 0.0}
        
        # Approximate the polygon
        peri = cv2.arcLength(largest_contour, True)
        epsilon = 0.04 * peri  # Tolerance for approximation
        approx = cv2.approxPolyDP(largest_contour, epsilon, True)
        
        vertices = len(approx)
        
        # Determine shape based on vertices
        if vertices == 3:
            shape = "triangle"
            confidence = self._calculate_shape_confidence(largest_contour, approx, "triangle")
        elif vertices == 4:
            # Check if it's a square or rectangle
            (x, y, w, h) = cv2.boundingRect(approx)
            aspect_ratio = float(w) / h
            if 0.85 <= aspect_ratio <= 1.15:
                shape = "square"
            else:
                shape = "rectangle"
            confidence = self._calculate_shape_confidence(largest_contour, approx, "square")
        elif vertices > 6:
            # Many vertices suggest a circle
            shape = "circle"
            confidence = self._calculate_circularity(largest_contour)
        else:
            shape = self.SHAPE_NAMES.get(vertices, f"polygon_{vertices}")
            confidence = 0.5
        
        return {"shape": shape, "vertices": vertices, "confidence": confidence}
    
    def _calculate_shape_confidence(self, contour: np.ndarray, approx: np.ndarray, expected_shape: str) -> float:
        """Calculate confidence score for shape detection."""
        area = cv2.contourArea(contour)
        perimeter = cv2.arcLength(contour, True)
        
        if perimeter == 0:
            return 0.0
        
        # Compactness measure
        compactness = 4 * np.pi * area / (perimeter ** 2)
        
        if expected_shape == "triangle":
            # Perfect triangle has compactness ~0.6
            ideal_compactness = 0.6
            confidence = 1 - min(abs(compactness - ideal_compactness) / ideal_compactness, 1.0)
        elif expected_shape == "square":
            # Perfect square has compactness ~0.785
            ideal_compactness = 0.785
            confidence = 1 - min(abs(compactness - ideal_compactness) / ideal_compactness, 1.0)
        else:
            confidence = 0.5
        
        return round(min(max(confidence, 0.0), 1.0), 2)
    
    def _calculate_circularity(self, contour: np.ndarray) -> float:
        """Calculate how circular a contour is (1.0 = perfect circle)."""
        area = cv2.contourArea(contour)
        perimeter = cv2.arcLength(contour, True)
        
        if perimeter == 0:
            return 0.0
        
        circularity = 4 * np.pi * area / (perimeter ** 2)
        return round(min(circularity, 1.0), 2)
    
    def _detect_dominant_color(self, image: np.ndarray) -> dict:
        """
        Detect the dominant color in the drawing.
        
        Returns dict with color name and confidence.
        """
        # Convert to HSV
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        
        # Create mask for non-white/non-background pixels
        # Assuming white or light gray background
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        _, drawing_mask = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
        
        total_drawing_pixels = cv2.countNonZero(drawing_mask)
        
        if total_drawing_pixels == 0:
            return {"color": "unknown", "confidence": 0.0}
        
        color_scores = {}
        
        # Check each color range
        for color_name, ranges in self.COLOR_RANGES.items():
            if color_name.startswith("red_"):
                continue  # Handle red specially below
                
            mask = cv2.inRange(hsv, ranges["lower"], ranges["upper"])
            # Combine with drawing mask
            combined_mask = cv2.bitwise_and(mask, drawing_mask)
            color_pixels = cv2.countNonZero(combined_mask)
            
            if total_drawing_pixels > 0:
                color_scores[color_name] = color_pixels / total_drawing_pixels
        
        # Handle red (wraps around HSV)
        red_low = cv2.inRange(hsv, self.COLOR_RANGES["red_low"]["lower"], self.COLOR_RANGES["red_low"]["upper"])
        red_high = cv2.inRange(hsv, self.COLOR_RANGES["red_high"]["lower"], self.COLOR_RANGES["red_high"]["upper"])
        red_mask = cv2.bitwise_or(red_low, red_high)
        red_combined = cv2.bitwise_and(red_mask, drawing_mask)
        red_pixels = cv2.countNonZero(red_combined)
        color_scores["red"] = red_pixels / total_drawing_pixels if total_drawing_pixels > 0 else 0
        
        # Find dominant color
        if not color_scores:
            return {"color": "unknown", "confidence": 0.0}
        
        dominant_color = max(color_scores, key=color_scores.get)
        confidence = color_scores[dominant_color]
        
        # If confidence is too low, mark as unknown
        if confidence < 0.1:
            return {"color": "unknown", "confidence": confidence}
        
        return {"color": dominant_color, "confidence": round(confidence, 2)}
    
    def _calculate_coverage(self, image: np.ndarray) -> float:
        """
        Calculate what fraction of the canvas has been drawn on.
        
        Returns a value between 0.0 and 1.0.
        """
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        _, drawing_mask = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
        
        total_pixels = image.shape[0] * image.shape[1]
        drawn_pixels = cv2.countNonZero(drawing_mask)
        
        return drawn_pixels / total_pixels if total_pixels > 0 else 0.0
    
    def _generate_feedback(
        self, 
        detected_shape: str, 
        detected_color: str,
        target_shape: str, 
        target_color: str,
        is_correct: bool,
        coverage: float = 0.0,
        has_enough_coverage: bool = True
    ) -> Tuple[str, str]:
        """
        Generate user-friendly feedback message and Pixy emotion.
        
        Returns (message, pixy_emotion)
        """
        if is_correct:
            return (
                f"Amazing! You drew a perfect {target_color} {target_shape}! 🎉",
                "happy"
            )
        
        shape_match = detected_shape == target_shape
        color_match = detected_color == target_color
        
        # Shape and color match but not enough coverage
        if shape_match and color_match and not has_enough_coverage:
            pct = int(coverage * 100)
            return (
                f"Good start! I can see a {target_color} {target_shape}, but draw more! Only {pct}% of the canvas is filled. Fill more of the shape! 🖍️",
                "encouraging"
            )
        
        if not shape_match and not color_match:
            return (
                f"Hmm, I see a {detected_color} {detected_shape}. Let's try to draw a {target_color} {target_shape}!",
                "encouraging"
            )
        elif not shape_match:
            hints = {
                "triangle": "Remember, a triangle has 3 corners!",
                "square": "A square has 4 equal sides!",
                "circle": "Try to make it round!"
            }
            hint = hints.get(target_shape, f"Try drawing a {target_shape}!")
            return (
                f"Great {detected_color} color! But I see a {detected_shape}. {hint}",
                "encouraging"
            )
        else:  # color mismatch
            return (
                f"Nice {detected_shape}! But can you make it {target_color}? Look at the color palette! 🎨",
                "hint_color"
            )


# Singleton instance
drawing_service = DrawingService()
