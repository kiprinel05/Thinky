"""Unit tests for GroupingMissionService. In-memory session, no DB."""
import pytest

from features.grouping.service import GroupingMissionService


@pytest.fixture
def service():
    return GroupingMissionService()


class TestStartMission:
    def test_start_returns_three_rounds_and_categories(self, service):
        resp = service.start_mission()
        assert resp.current_round == 1
        assert resp.total_rounds == 3
        assert set(resp.categories) == {"fruits", "vegetables", "toys"}


class TestGetRound:
    def test_round_contains_items_from_all_categories(self, service):
        service.start_mission()
        round_resp = service.get_round()
        assert round_resp.round_number == 1
        assert round_resp.total_rounds == 3
        # Each item's label is one of the canonical categories.
        labels = {it.label for it in round_resp.items}
        assert labels.issubset({"fruits", "vegetables", "toys"})
        # At least one item per category (start uses 3 items per category by default).
        assert labels == {"fruits", "vegetables", "toys"}

    def test_get_round_after_three_rounds_raises(self, service):
        service.start_mission()
        for _ in range(3):
            service.get_round()
            # Simulate completion so internal counters advance.
            assignments = {it.id: it.label for it in service._session["current_items"]}
            service.validate_grouping(assignments, time_spent=10.0)

        with pytest.raises(ValueError, match="Mission already complete"):
            service.get_round()


class TestValidateGrouping:
    def test_all_correct_assignments_give_perfect_accuracy(self, service):
        service.start_mission()
        round_resp = service.get_round()
        assignments = {it.id: it.label for it in round_resp.items}

        result = service.validate_grouping(assignments, time_spent=12.5)

        assert result.is_correct is True
        assert result.accuracy == 1.0
        assert result.correct_count == result.total_count
        assert result.time_spent == 12.5
        assert result.pixy_emotion == "happy"

    def test_half_correct_assignments_give_half_accuracy(self, service):
        service.start_mission()
        round_resp = service.get_round()
        items = round_resp.items
        # Correct for half, wrong for the rest.
        wrong_label = {"fruits": "toys", "vegetables": "fruits", "toys": "vegetables"}
        assignments = {}
        for i, it in enumerate(items):
            assignments[it.id] = it.label if i % 2 == 0 else wrong_label[it.label]

        result = service.validate_grouping(assignments, time_spent=20.0)

        expected_correct = sum(1 for i, _ in enumerate(items) if i % 2 == 0)
        assert result.correct_count == expected_correct
        assert result.total_count == len(items)
        assert result.accuracy == round(expected_correct / len(items), 2)
        assert result.is_correct is False

    def test_unassigned_items_count_as_wrong(self, service):
        service.start_mission()
        round_resp = service.get_round()
        # No assignments at all.
        result = service.validate_grouping({}, time_spent=5.0)
        assert result.correct_count == 0
        assert result.accuracy == 0.0
        for d in result.details:
            assert d.user_category == "unassigned"
            assert d.is_correct is False

    def test_validate_without_active_round_raises(self, service):
        service.start_mission()
        with pytest.raises(ValueError, match="No active round"):
            service.validate_grouping({}, time_spent=0.0)


class TestMissionSummary:
    def test_summary_zero_before_any_round(self, service):
        s = service.get_mission_summary()
        assert s == {"avg_accuracy": 0, "total_time": 0, "rounds": 0}

    def test_summary_aggregates_completed_rounds(self, service):
        service.start_mission()
        for _ in range(2):
            round_resp = service.get_round()
            assignments = {it.id: it.label for it in round_resp.items}
            service.validate_grouping(assignments, time_spent=10.0)

        s = service.get_mission_summary()
        assert s["rounds"] == 2
        assert s["avg_accuracy"] == 1.0
        assert s["total_time"] == 20.0
