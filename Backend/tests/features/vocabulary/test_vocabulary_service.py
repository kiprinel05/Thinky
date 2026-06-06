"""Unit tests for VocabularyMissionService — pure in-memory session."""
import random

import pytest

from features.vocabulary.schemas import VocabAnswerRequest
from features.vocabulary.service import VocabularyMissionService


@pytest.fixture
def service():
    random.seed(0)
    return VocabularyMissionService()


class TestStartMission:
    def test_default_starts_eight_questions(self, service):
        resp = service.start_mission()
        assert resp.totalQuestions == VocabularyMissionService.QUESTIONS_PER_MISSION
        assert len(resp.questions) == 8

    def test_explicit_count_overrides_default(self, service):
        resp = service.start_mission(num_questions=3)
        assert resp.totalQuestions == 3
        assert len(resp.questions) == 3

    def test_each_question_has_correct_image_in_options(self, service):
        resp = service.start_mission(num_questions=5)
        for q in resp.questions:
            ids = {img.id for img in q.images}
            assert q.correctImageId in ids
            # First question's correct id = 0*100 + 1, second = 100 + 1, etc.
            # Use the contract that correct id ends in 1 and is unique per question.

    def test_correct_id_per_question_follows_base_scheme(self, service):
        resp = service.start_mission(num_questions=4)
        for q_idx, q in enumerate(resp.questions):
            assert q.correctImageId == q_idx * 100 + 1


class TestValidateAnswer:
    def test_correct_selection_returns_correct_true(self, service):
        service.start_mission(num_questions=2)
        q0 = service._session["questions"][0]
        resp = service.validate_answer(
            VocabAnswerRequest(questionIndex=0, selectedImageId=q0.correctImageId)
        )
        assert resp.success is True
        assert resp.correct is True
        assert resp.correctImageId == q0.correctImageId
        assert resp.progress["completed"] == 1

    def test_wrong_selection_returns_correct_false(self, service):
        service.start_mission(num_questions=2)
        q0 = service._session["questions"][0]
        wrong_id = next(img.id for img in q0.images if img.id != q0.correctImageId)
        resp = service.validate_answer(
            VocabAnswerRequest(questionIndex=0, selectedImageId=wrong_id)
        )
        assert resp.correct is False

    def test_validate_without_start_raises(self, service):
        with pytest.raises(ValueError, match="No active mission"):
            service.validate_answer(
                VocabAnswerRequest(questionIndex=0, selectedImageId=1)
            )

    @pytest.mark.parametrize("bad", [-1, 999])
    def test_invalid_question_index_raises(self, service, bad):
        service.start_mission(num_questions=2)
        with pytest.raises(ValueError, match="Invalid question index"):
            service.validate_answer(
                VocabAnswerRequest(questionIndex=bad, selectedImageId=1)
            )


class TestProgress:
    def test_initial_progress_is_zero(self, service):
        service.start_mission(num_questions=3)
        p = service.get_progress()
        assert p.completed == 0
        assert p.total == 3
        assert p.correctCount == 0
        assert p.accuracy == 0.0

    def test_partial_progress_accuracy(self, service):
        service.start_mission(num_questions=2)
        qs = service._session["questions"]
        # 1 correct + 1 wrong
        service.validate_answer(VocabAnswerRequest(questionIndex=0, selectedImageId=qs[0].correctImageId))
        wrong = next(img.id for img in qs[1].images if img.id != qs[1].correctImageId)
        service.validate_answer(VocabAnswerRequest(questionIndex=1, selectedImageId=wrong))

        p = service.get_progress()
        assert p.completed == 2
        assert p.correctCount == 1
        assert p.accuracy == 0.5
        assert qs[1].wordEn in p.incorrectWordsEn
