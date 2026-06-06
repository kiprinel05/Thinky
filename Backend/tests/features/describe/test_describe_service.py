"""Tests for DescribeMissionService matching logic. OpenAI client is NOT exercised."""
import random

import pytest

from features.describe.service import (
    DescribeMissionService,
    ROUNDS_PER_MISSION,
    _normalise,
    _score_against,
)


class TestNormalise:
    def test_lowercases_and_strips_punctuation(self):
        assert _normalise("Hello, WORLD!") == "hello world"

    def test_strips_romanian_diacritics(self):
        assert _normalise("Câine maro") == "caine maro"
        assert _normalise("Pisică portocalie") == "pisica portocalie"

    def test_collapses_whitespace(self):
        assert _normalise("a   b\tc\n d") == "a b c d"


class TestScoreAgainst:
    def test_returns_matched_and_missing(self):
        matched, missing = _score_against("there is a dog in the park", ["dog", "park", "tree"])
        assert set(matched) == {"dog", "park"}
        assert missing == ["tree"]

    def test_word_boundary_prevents_substring_match(self):
        # "cat" must not match "scatter"
        matched, missing = _score_against("scatter the seeds", ["cat"])
        assert matched == []
        assert missing == ["cat"]

    def test_romanian_keyword_matches_against_diacritic_stripped_input(self):
        # Input has been normalised already by callers.
        norm = _normalise("Văd un câine maro în parc")
        matched, _ = _score_against(norm, ["câine", "maro", "parc"])
        assert set(matched) == {"câine", "maro", "parc"}


@pytest.fixture
def service():
    random.seed(0)
    s = DescribeMissionService()
    # Avoid talking to the real OpenAI API in any code path.
    s._openai_client = None
    return s


class TestStartMission:
    def test_start_returns_five_unique_rounds(self, service):
        resp = service.start_mission()
        assert resp.totalRounds == ROUNDS_PER_MISSION == 5
        assert len(resp.questions) == 5
        ids = [q.id for q in resp.questions]
        assert len(ids) == len(set(ids))


class TestValidateRound:
    def test_perfect_english_description_passes(self, service):
        service.start_mission()
        # Pick first round and build a description containing ALL of its EN keywords.
        item = service._session["questions"][0]
        text = " ".join(item.keywordsEn)
        resp = service.validate_round(question_index=0, transcription=text)
        assert resp.success is True
        assert resp.correct is True
        assert resp.result.detectedLang == "en"
        assert resp.result.matchScore == 1.0

    def test_romanian_description_picks_ro_lang(self, service):
        service.start_mission()
        item = service._session["questions"][0]
        text = " ".join(item.keywordsRo)
        resp = service.validate_round(question_index=0, transcription=text)
        assert resp.result.detectedLang == "ro"
        assert resp.result.matchScore == 1.0

    def test_below_threshold_marks_incorrect(self, service):
        service.start_mission()
        item = service._session["questions"][0]
        # Only the first keyword → 1/5 = 0.2, threshold is 0.4
        resp = service.validate_round(question_index=0, transcription=item.keywordsEn[0])
        assert resp.correct is False

    def test_invalid_index_returns_no_session_result(self, service):
        service.start_mission()
        resp = service.validate_round(question_index=99, transcription="anything")
        assert resp.success is False
        assert resp.result.success is False

    def test_no_active_session_returns_no_session_result(self, service):
        # Don't call start_mission. The service auto-resets in __init__ so
        # questions exist; clear them to simulate truly empty state.
        service._session["questions"] = []
        resp = service.validate_round(question_index=0, transcription="anything")
        assert resp.success is False
