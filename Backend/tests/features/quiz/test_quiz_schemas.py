"""Pydantic validation tests for quiz schemas."""
import pytest
from pydantic import ValidationError

from features.quiz.schemas import (
    AnswerOption,
    AnswerSubmission,
    Question,
    QuizResponse,
    QuizResultResponse,
    QuizSubmission,
)


class TestAnswerSubmission:
    def test_valid(self):
        a = AnswerSubmission(question_id=1, answer_id=3)
        assert a.question_id == 1
        assert a.answer_id == 3

    def test_missing_field_raises(self):
        with pytest.raises(ValidationError):
            AnswerSubmission(question_id=1)  # type: ignore[call-arg]


class TestQuizSubmission:
    def test_valid_with_multiple_answers(self):
        sub = QuizSubmission(
            answers=[
                AnswerSubmission(question_id=1, answer_id=1),
                AnswerSubmission(question_id=2, answer_id=2),
            ]
        )
        assert len(sub.answers) == 2

    def test_empty_answers_list_is_allowed(self):
        # Empty list is structurally valid; the *service* decides how to score it.
        sub = QuizSubmission(answers=[])
        assert sub.answers == []


class TestQuizResultResponse:
    def test_model_validate_from_orm_like_object(self):
        # Mimics SQLAlchemy attribute access (model_config has from_attributes=True).
        class _Row:
            score = 4
            total_questions = 5
            percentage = 80.0
            correct_answers = 4
            incorrect_answers = 1
            xp_earned = 50

        r = QuizResultResponse.model_validate(_Row())
        assert r.xp_earned == 50
        assert r.percentage == 80.0
        assert r.score == 4


class TestQuestionShapes:
    def test_quiz_response_shape(self):
        q = Question(
            id=1,
            question="What is AI?",
            options=[AnswerOption(id=1, text="A"), AnswerOption(id=2, text="B")],
            correct_answer_id=1,
            explanation="because",
        )
        resp = QuizResponse(questions=[q], total_questions=1)
        assert resp.total_questions == 1
        assert resp.questions[0].options[0].text == "A"
