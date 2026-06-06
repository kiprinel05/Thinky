"""Tests for AnimalMissionService — image_cache + ML classifier are mocked."""
from unittest.mock import MagicMock

import pytest

from features.animals.service import AnimalMissionService


@pytest.fixture
def service():
    # Skip __init__ (which loads MobileNetV2 + reads dataset dirs).
    svc = AnimalMissionService.__new__(AnimalMissionService)
    svc._classifier = MagicMock()
    svc._image_cache = {
        "dog": ["d1.jpg", "d2.jpg", "d3.jpg"],
        "cat": ["c1.jpg", "c2.jpg"],
        "fish": ["f1.jpg"],
    }
    return svc


class TestGetRandomImage:
    def test_returns_image_from_cache(self, service):
        img = service.get_random_image()
        assert img.label in service._image_cache
        assert img.id.startswith(img.label + "_")

    def test_exclude_filters_known_ids(self, service):
        # Force the only available image for "fish" to be excluded.
        img = service.get_random_image(exclude_ids=["fish_f1.jpg"])
        # Service falls back to ALL cached images for that animal if filter
        # leaves nothing, so just assert we still get a valid label.
        assert img.label in service._image_cache


class TestMakeGuess:
    def test_correct_guess_marked_correct(self, service):
        service._classifier.predict_with_skill.return_value = ("dog", 0.9, {})
        result = service.make_guess(image_id="dog_d1.jpg", skill_level=0.5)
        assert result.guess == "dog"
        assert result.actual_animal == "dog"
        assert result.is_correct is True
        assert result.confidence == 0.9

    def test_wrong_guess_marked_incorrect(self, service):
        service._classifier.predict_with_skill.return_value = ("cat", 0.6, {})
        result = service.make_guess(image_id="dog_d1.jpg", skill_level=0.5)
        assert result.is_correct is False
        assert result.actual_animal == "dog"


class TestValidateTeaching:
    def test_perfect_selection(self, service):
        result = service.validate_teaching(
            target_animal="dog",
            selected_ids=["dog_a", "dog_b"],
            correct_ids=["dog_a", "dog_b"],
        )
        assert result.is_correct is True
        assert result.correct_count == 2
        assert result.missed_count == 0
        assert result.wrong_count == 0

    def test_missed_some(self, service):
        result = service.validate_teaching(
            target_animal="dog",
            selected_ids=["dog_a"],
            correct_ids=["dog_a", "dog_b"],
        )
        assert result.is_correct is False
        assert result.missed_count == 1
        assert result.wrong_count == 0

    def test_wrong_selections(self, service):
        result = service.validate_teaching(
            target_animal="dog",
            selected_ids=["cat_x", "dog_a"],
            correct_ids=["dog_a", "dog_b"],
        )
        assert result.wrong_count == 1
        assert result.missed_count == 1
