"""Unit tests for PatternMissionService. Pure in-memory, no DB."""
import random

import pytest

from features.pattern.service import (
    DIFFICULTY_PLAN,
    MISSION_ID,
    TOTAL_ROUNDS,
    PatternMissionService,
)


@pytest.fixture
def service():
    # Seed random so option/distractor selection is reproducible per test.
    random.seed(0)
    return PatternMissionService()


class TestStartMission:
    def test_returns_five_rounds(self, service):
        resp = service.start_mission()
        assert resp.missionId == MISSION_ID
        assert resp.totalRounds == TOTAL_ROUNDS == 5
        assert len(resp.questions) == 5

    def test_each_round_has_three_options_with_base_id(self, service):
        resp = service.start_mission()
        for round_idx, q in enumerate(resp.questions):
            assert q.index == round_idx
            assert q.difficulty == DIFFICULTY_PLAN[round_idx]
            assert len(q.options) == 3
            # `base = (round_idx+1) * 100` is the correct option's id by contract.
            base = (round_idx + 1) * 100
            option_ids = {opt.id for opt in q.options}
            assert base in option_ids
            # Distractors are base + 1, base + 2
            assert option_ids == {base, base + 1, base + 2}


class TestValidateAnswer:
    def test_correct_answer_marks_round_as_correct(self, service):
        service.start_mission()
        # Correct id for round 0 is `base = 100` (see start contract).
        result = service.validate_answer(question_index=0, selected_option_id=100)
        assert result.success is True
        assert result.correct is True
        assert result.correctOptionId == 100
        assert result.progress.completed == 1
        assert result.progress.total == TOTAL_ROUNDS

    def test_wrong_answer_returns_correct_id_for_feedback(self, service):
        service.start_mission()
        result = service.validate_answer(question_index=0, selected_option_id=101)
        assert result.success is True
        assert result.correct is False
        assert result.correctOptionId == 100

    @pytest.mark.parametrize("bad_index", [-1, 5, 999])
    def test_invalid_index_fails_soft(self, service, bad_index):
        service.start_mission()
        result = service.validate_answer(question_index=bad_index, selected_option_id=100)
        # Service contract: never raise, return success=False + sentinel id.
        assert result.success is False
        assert result.correct is False
        assert result.correctOptionId == -1


class TestProgress:
    def test_empty_progress_at_start(self, service):
        service.start_mission()
        p = service.get_progress()
        assert p.completed == 0
        assert p.total == TOTAL_ROUNDS
        assert p.correctCount == 0
        assert p.accuracy == 0.0

    def test_accuracy_after_two_rounds(self, service):
        service.start_mission()
        # Round 0 correct (base=100), round 1 wrong.
        service.validate_answer(0, 100)
        service.validate_answer(1, 201)  # 201 is a distractor
        p = service.get_progress()
        assert p.completed == 2
        assert p.correctCount == 1
        assert p.accuracy == 0.5

    def test_start_mission_resets_state(self, service):
        service.start_mission()
        service.validate_answer(0, 100)
        service.start_mission()  # restart
        p = service.get_progress()
        assert p.completed == 0
        assert p.correctCount == 0
