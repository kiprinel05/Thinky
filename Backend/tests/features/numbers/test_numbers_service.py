"""Tests for NumbersService — covers state machine, model upgrade, professor cues.

Real CNN inference and DB writes are bypassed via mocks: the service only
needs a mission_repository handle and the digit_recognition_service in the
drawing flow.
"""
from unittest.mock import MagicMock, patch

import pytest

from features.numbers.schemas import CountingSubmission, TeachDrawingSubmission
from features.numbers.service import (
    CONFUSION_THRESHOLD,
    CORRECT_TO_UPGRADE,
    MODEL_LEVELS,
    NumbersService,
)


@pytest.fixture(autouse=True)
def _clear_class_sessions():
    """`_sessions` is a class-level dict — leaks between tests if not cleared."""
    NumbersService._sessions.clear()
    yield
    NumbersService._sessions.clear()


@pytest.fixture
def service():
    return NumbersService(mission_repository=MagicMock())


class TestStartSession:
    def test_start_creates_session_with_defaults(self, service):
        resp = service.start_session(user_id=1, lang="en")
        assert resp.target_number in range(1, 6)
        assert resp.model_level == "junior"
        assert resp.current_part == 1
        assert len(resp.objects) == resp.target_number


class TestSubmitCount:
    def test_correct_count_increments_correct_counter(self, service):
        service.start_session(user_id=1)
        target = service._sessions[1]["target_number"]
        service.submit_count(1, CountingSubmission(answer=target))
        assert service._sessions[1]["total_correct"] == 1

    def test_two_consecutive_wrong_triggers_professor(self, service):
        service.start_session(user_id=1)
        target = service._sessions[1]["target_number"]
        wrong = (target % 5) + 1  # always different from target
        resp1 = service.submit_count(1, CountingSubmission(answer=wrong))
        assert resp1.show_professor is False
        # Force the new target after first submission so we can reliably pick wrong.
        target2 = service._sessions[1]["target_number"]
        wrong2 = (target2 % 5) + 1
        resp2 = service.submit_count(1, CountingSubmission(answer=wrong2))
        # CONFUSION_THRESHOLD = 2 → second wrong triggers professor.
        assert CONFUSION_THRESHOLD == 2
        assert resp2.show_professor is True
        assert resp2.professor_message is not None

    def test_three_correct_answers_upgrade_model(self, service):
        service.start_session(user_id=1)
        for _ in range(CORRECT_TO_UPGRADE):
            target = service._sessions[1]["target_number"]
            service.submit_count(1, CountingSubmission(answer=target))
        # After CORRECT_TO_UPGRADE consecutive correct counts, model upgrades.
        assert service._sessions[1]["model_level"] == MODEL_LEVELS[1]  # "student"


class TestSubmitDrawing:
    @patch("features.numbers.service.digit_recognition_service")
    def test_uses_truth_digit_from_recognizer(self, mock_recognizer, service):
        mock_recognizer.recognize_truth.return_value = (7, 0.9)
        service.start_session(user_id=1)

        resp = service.submit_drawing(user_id=1, image_bytes=b"fake")

        assert resp.guessed_digit == 7
        # Display confidence floor at example #0 is 0.30; raw 0.9 wins.
        assert resp.confidence == pytest.approx(0.9, rel=1e-3)
        assert resp.awaiting_confirmation is True

    @patch("features.numbers.service.digit_recognition_service")
    def test_confidence_floor_grows_with_examples(self, mock_recognizer, service):
        mock_recognizer.recognize_truth.return_value = (3, 0.10)  # low raw
        service.start_session(user_id=1)
        # No examples yet → floor = 0.30
        resp1 = service.submit_drawing(1, b"x")
        assert resp1.confidence == pytest.approx(0.30, rel=1e-3)
        # Bump examples_taught directly to exercise the floor curve.
        service._sessions[1]["examples_taught"] = 4
        resp2 = service.submit_drawing(1, b"x")
        # floor = min(1.0, 0.30 + 0.18*4) = 1.02 → clamped to 1.0
        assert resp2.confidence == 1.0


class TestTeachDrawing:
    @patch("features.numbers.service.digit_recognition_service")
    def test_correct_confirmation_increments_examples(self, mock_recognizer, service):
        mock_recognizer.recognize_truth.return_value = (5, 0.9)
        service.start_session(1)
        service.submit_drawing(1, b"x")

        resp = service.teach_drawing(1, TeachDrawingSubmission(claimed_digit=5))

        assert resp.was_pixy_correct is True
        assert resp.is_lying is False
        assert resp.examples_taught == 1
        assert resp.pixy_emotion == "happy"

    @patch("features.numbers.service.digit_recognition_service")
    def test_lying_detected_when_recognizer_was_confident(
        self, mock_recognizer, service
    ):
        # Recognizer is very sure it was a 5; child claims it was a 9.
        mock_recognizer.recognize_truth.return_value = (5, 0.95)
        service.start_session(1)
        service.submit_drawing(1, b"x")

        resp = service.teach_drawing(1, TeachDrawingSubmission(claimed_digit=9))

        assert resp.is_lying is True
        assert resp.show_professor is True
        assert resp.professor_message is not None
        # Examples NOT counted on a lie.
        assert resp.examples_taught == 0

    @patch("features.numbers.service.digit_recognition_service")
    def test_low_confidence_correction_is_not_lying(self, mock_recognizer, service):
        # Recognizer is unsure (below CHEATING_CONFIDENCE_THRESHOLD = 0.70).
        mock_recognizer.recognize_truth.return_value = (3, 0.40)
        service.start_session(1)
        service.submit_drawing(1, b"x")

        resp = service.teach_drawing(1, TeachDrawingSubmission(claimed_digit=8))

        assert resp.is_lying is False
        assert resp.was_pixy_correct is False
        assert resp.examples_taught == 1  # counted as a valid teaching example


class TestGetProgress:
    def test_progress_reflects_session_state(self, service):
        service.start_session(1)
        service._sessions[1]["rounds_completed"] = 4
        service._sessions[1]["total_correct"] = 3
        prog = service.get_progress(1)
        assert prog.rounds_completed == 4
        assert prog.score == pytest.approx(75.0)
