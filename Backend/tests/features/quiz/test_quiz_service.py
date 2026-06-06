"""Service-layer tests for QuizService. Repository is mocked — no DB needed."""
from unittest.mock import MagicMock

import pytest

from features.quiz.schemas import AnswerSubmission, QuizSubmission
from features.quiz.service import QUIZ_QUESTIONS, QuizService


@pytest.fixture
def quiz_service():
    mock_repo = MagicMock()
    mock_repo.db = MagicMock()
    return QuizService(mock_repo)


def _submission_with_correct_count(n: int) -> QuizSubmission:
    """Build a submission where exactly the first `n` questions are correct."""
    answers = []
    for i, q in enumerate(QUIZ_QUESTIONS):
        if i < n:
            answers.append(AnswerSubmission(question_id=q["id"], answer_id=q["correct_answer_id"]))
        else:
            # Pick any wrong answer id.
            wrong = next(opt["id"] for opt in q["options"] if opt["id"] != q["correct_answer_id"])
            answers.append(AnswerSubmission(question_id=q["id"], answer_id=wrong))
    return QuizSubmission(answers=answers)


class TestGetQuestions:
    def test_returns_all_five_questions(self, quiz_service):
        # Act
        resp = quiz_service.get_questions()
        # Assert
        assert resp.total_questions == 5
        assert len(resp.questions) == 5
        for q in resp.questions:
            assert len(q.options) == 4
            # correct_answer_id must reference one of the option ids
            assert q.correct_answer_id in {opt.id for opt in q.options}


class TestSubmitQuiz:
    @pytest.mark.parametrize(
        "correct,expected_pct,expected_xp",
        [
            (5, 100.0, 50),  # perfect
            (4,  80.0, 50),  # threshold for 50 XP
            (3,  60.0, 30),  # mid tier
            (2,  40.0, 10),  # below 50%
            (1,  20.0, 10),
            (0,   0.0, 10),
        ],
    )
    def test_xp_thresholds(self, quiz_service, correct, expected_pct, expected_xp):
        # Arrange
        submission = _submission_with_correct_count(correct)
        # Act
        result = quiz_service.submit_quiz(user_id=42, submission=submission)
        # Assert
        assert result.score == correct
        assert result.percentage == expected_pct
        assert result.xp_earned == expected_xp
        assert result.correct_answers == correct
        assert result.incorrect_answers == 5 - correct

    def test_empty_submission_scores_zero_and_earns_ten_xp(self, quiz_service):
        result = quiz_service.submit_quiz(
            user_id=1, submission=QuizSubmission(answers=[])
        )
        assert result.score == 0
        assert result.percentage == 0.0
        assert result.xp_earned == 10

    def test_unknown_question_id_does_not_credit_score(self, quiz_service):
        result = quiz_service.submit_quiz(
            user_id=1,
            submission=QuizSubmission(
                answers=[AnswerSubmission(question_id=999, answer_id=1)]
            ),
        )
        assert result.score == 0

    def test_quiz_result_is_persisted(self, quiz_service):
        # Act
        quiz_service.submit_quiz(user_id=42, submission=_submission_with_correct_count(5))
        # Assert
        quiz_service.repository.db.add.assert_called_once()
        quiz_service.repository.db.commit.assert_called_once()
        quiz_service.repository.db.refresh.assert_called_once()
        added = quiz_service.repository.db.add.call_args[0][0]
        assert added.user_id == 42
        assert added.score == 5
        assert added.xp_earned == 50
