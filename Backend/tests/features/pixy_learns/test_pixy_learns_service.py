"""Tests for PixyLearnsService — repository mocked; no DB except the mission lookup."""
from unittest.mock import MagicMock

import pytest

from features.pixy_learns.schemas import LabelRequest, LabelSubmission
from features.pixy_learns.service import PixyLearnsService


@pytest.fixture(autouse=True)
def _clear_class_state():
    PixyLearnsService._current_images.clear()
    yield
    PixyLearnsService._current_images.clear()


@pytest.fixture
def service():
    repo = MagicMock()
    # Mission lookup returns None by default → no DB write attempt.
    repo.db.query.return_value.filter.return_value.first.return_value = None
    return PixyLearnsService(mission_repository=repo)


class TestGetImages:
    def test_returns_six_images_three_cats_three_apples(self, service):
        resp = service.get_images()
        assert resp["total"] == 6
        assert len(resp["images"]) == 6

    def test_stores_correct_labels_in_session(self, service):
        service.get_images()
        labels = list(service._current_images.values())
        assert labels.count("cat") == 3
        assert labels.count("apple") == 3


class TestProcessSubmission:
    def test_all_correct_completes_mission(self, service):
        service.get_images()
        # Build a submission with the correct label per image.
        labels = [
            LabelRequest(image_id=img_id, label=correct)
            for img_id, correct in service._current_images.items()
        ]
        result = service.process_submission(user_id=1, submission=LabelSubmission(labels=labels))

        assert result.is_complete is True
        assert result.learned_examples == 6
        assert result.progress_percentage == 100.0

    def test_partial_correct_does_not_complete(self, service):
        service.get_images()
        items = list(service._current_images.items())
        # First three correct, last three wrong.
        labels = []
        for i, (img_id, correct) in enumerate(items):
            labels.append(LabelRequest(
                image_id=img_id,
                label=correct if i < 3 else ("apple" if correct == "cat" else "cat"),
            ))
        result = service.process_submission(user_id=1, submission=LabelSubmission(labels=labels))

        assert result.is_complete is False
        assert result.learned_examples == 3
        assert result.progress_percentage == 50.0

    def test_session_is_cleared_after_submission(self, service):
        service.get_images()
        result = service.process_submission(
            user_id=1, submission=LabelSubmission(labels=[])
        )
        assert service._current_images == {}
        assert result.learned_examples == 0
