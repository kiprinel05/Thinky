"""Tests for DrawingService helpers + analyze_drawing with the CNN mocked."""
from unittest.mock import MagicMock

import pytest

from features.drawing.service import (
    DrawingService,
    _generate_feedback,
    _shapes_match,
)


class TestShapesMatch:
    @pytest.mark.parametrize(
        "detected,target,expected",
        [
            ("triangle", "triangle", True),
            ("rectangle", "square", True),   # alias
            ("square", "rectangle", True),   # alias
            ("circle", "ellipse", True),
            ("ellipse", "circle", True),
            ("triangle", "circle", False),
        ],
    )
    def test_aliases(self, detected, target, expected):
        assert _shapes_match(detected, target) is expected


class TestGenerateFeedback:
    def test_scribble_dominates_all_other_signals(self):
        msg, emotion = _generate_feedback(
            "circle", "blue", "circle", "blue",
            is_correct=True, coverage=1.0, has_enough_coverage=True,
            require_fill=False, is_scribble=True, is_too_small_flag=False,
            shape_confidence=0.95,
        )
        assert "scribble" in msg.lower()
        assert emotion == "encouraging"

    def test_too_small_message(self):
        msg, emotion = _generate_feedback(
            "circle", "blue", "circle", "blue",
            is_correct=False, coverage=0.005, has_enough_coverage=False,
            require_fill=False, is_scribble=False, is_too_small_flag=True,
            shape_confidence=0.9,
        )
        assert "small" in msg.lower()
        assert emotion == "encouraging"

    def test_perfect_match_is_happy(self):
        msg, emotion = _generate_feedback(
            "triangle", "blue", "triangle", "blue",
            is_correct=True, coverage=0.3, has_enough_coverage=True,
            require_fill=False, is_scribble=False, is_too_small_flag=False,
            shape_confidence=0.95,
        )
        assert emotion == "happy"
        assert "triangle" in msg.lower()

    def test_low_confidence_returns_unsure_hint(self):
        msg, emotion = _generate_feedback(
            "triangle", "blue", "triangle", "blue",
            is_correct=False, coverage=0.3, has_enough_coverage=True,
            require_fill=False, is_scribble=False, is_too_small_flag=False,
            shape_confidence=0.3,  # below 0.45 threshold
        )
        assert emotion == "encouraging"
        assert "not sure" in msg.lower() or "clear" in msg.lower()


class TestAnalyzeDrawing:
    @pytest.fixture
    def service(self):
        svc = DrawingService.__new__(DrawingService)
        svc.model = MagicMock()
        svc.model.is_loaded = True
        return svc

    def test_unreadable_image_bytes_returns_error_message(self, service):
        # Empty bytes → cv2.imdecode returns None.
        result = service.analyze_drawing(image_bytes=b"")
        assert result.is_correct is False
        assert result.pixy_emotion == "encouraging"
        # CNN should not have been called.
        service.model.predict.assert_not_called()
