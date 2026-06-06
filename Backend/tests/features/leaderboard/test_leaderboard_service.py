"""Tests for LeaderboardService — uses in-memory SQLite."""
import pytest

from features.auth.models import User
from features.quiz.models import QuizResult
from features.leaderboard.service import LeaderboardService


@pytest.fixture
def lb(db_session):
    return LeaderboardService(db_session)


def _add_user(db, *, username, is_guest=False) -> User:
    u = User(
        username=username,
        email=f"{username}@example.com",
        hashed_password="h",
        is_guest=is_guest,
        guest_name=username if is_guest else None,
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


def _award(db, user_id: int, slug: str, xp: int):
    db.add(QuizResult(
        user_id=user_id,
        quiz_type=slug,
        score=1,
        total_questions=1,
        percentage=100.0,
        correct_answers=1,
        incorrect_answers=0,
        xp_earned=xp,
    ))
    db.commit()


class TestLeaderboard:
    def test_empty_db_returns_empty_response(self, lb):
        resp = lb.get_leaderboard()
        assert resp.entries == []
        assert resp.stats.total_players == 0

    def test_ranking_sorted_by_xp_descending(self, lb, db_session):
        alice = _add_user(db_session, username="alice")
        bob = _add_user(db_session, username="bob")
        _award(db_session, alice.id, "pattern", 30)
        _award(db_session, bob.id, "pattern", 50)

        resp = lb.get_leaderboard()
        assert len(resp.entries) == 2
        # Higher XP first.
        assert resp.entries[0].username == "bob"
        assert resp.entries[0].xp == 50
        assert resp.entries[1].username == "alice"
        assert resp.entries[1].xp == 30

    def test_guests_excluded_from_leaderboard(self, lb, db_session):
        guest = _add_user(db_session, username="guest_kid", is_guest=True)
        registered = _add_user(db_session, username="alice")
        _award(db_session, guest.id, "pattern", 100)
        _award(db_session, registered.id, "pattern", 10)

        resp = lb.get_leaderboard()
        usernames = {e.username for e in resp.entries}
        assert "guest_kid" not in usernames
        assert "alice" in usernames

    def test_xp_aggregates_across_missions(self, lb, db_session):
        alice = _add_user(db_session, username="alice")
        _award(db_session, alice.id, "pattern", 30)
        _award(db_session, alice.id, "vocabulary", 50)

        resp = lb.get_leaderboard()
        assert resp.entries[0].xp == 80
        # mission_points contains per-slug breakdown.
        assert resp.entries[0].mission_points is not None
        slugs = {mp.mission_id for mp in resp.entries[0].mission_points}
        assert slugs == {"pattern", "vocabulary"}

    def test_stats_summary(self, lb, db_session):
        a = _add_user(db_session, username="a")
        b = _add_user(db_session, username="b")
        _award(db_session, a.id, "pattern", 10)
        _award(db_session, b.id, "pattern", 50)

        resp = lb.get_leaderboard()
        assert resp.stats.total_players == 2
        assert resp.stats.max_xp == 50.0
        assert resp.stats.min_xp == 10.0
        assert resp.stats.average_xp == 30.0

    def test_limit_truncates_entries(self, lb, db_session):
        for i in range(5):
            u = _add_user(db_session, username=f"u{i}")
            _award(db_session, u.id, "pattern", 10 * (i + 1))
        resp = lb.get_leaderboard(limit=3)
        assert len(resp.entries) == 3
        # Stats still computed over all 5 players.
        assert resp.stats.total_players == 5
