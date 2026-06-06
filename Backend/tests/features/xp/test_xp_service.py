"""Tests for XpService — uses the real in-memory SQLite via db_session."""
import pytest

from features.auth.models import User
from features.quiz.models import QuizResult
from features.xp.schemas import AwardXpRequest
from features.xp.service import XpService, compute_xp


@pytest.fixture
def xp_service(db_session):
    return XpService(db_session)


@pytest.fixture
def user(db_session):
    u = User(
        username="alice",
        email="alice@example.com",
        hashed_password="hash",
        is_guest=False,
    )
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


@pytest.fixture
def guest(db_session):
    g = User(
        guest_name="GuestKid",
        username="guest_abc",
        email="guest_abc@thinky.local",
        is_guest=True,
    )
    db_session.add(g)
    db_session.commit()
    db_session.refresh(g)
    return g


class TestComputeXp:
    @pytest.mark.parametrize(
        "pct,expected",
        [
            (100.0, 50),
            (80.0, 50),
            (79.99, 30),
            (50.0, 30),
            (49.99, 10),
            (0.0, 10),
        ],
    )
    def test_thresholds(self, pct, expected):
        assert compute_xp(pct) == expected


class TestAwardXp:
    def test_first_award_persists_and_returns_xp(self, xp_service, user, db_session):
        req = AwardXpRequest(mission_slug="pattern", score_percentage=85.0)
        resp = xp_service.award_xp(user, req)
        assert resp.xp_earned == 50
        assert resp.already_awarded is False
        assert resp.is_guest is False
        # Persisted as a QuizResult row.
        rows = db_session.query(QuizResult).filter_by(user_id=user.id).all()
        assert len(rows) == 1
        assert rows[0].quiz_type == "pattern"
        assert rows[0].xp_earned == 50

    def test_replay_returns_already_awarded(self, xp_service, user):
        req = AwardXpRequest(mission_slug="pattern", score_percentage=85.0)
        first = xp_service.award_xp(user, req)
        second = xp_service.award_xp(user, AwardXpRequest(mission_slug="pattern", score_percentage=100.0))
        assert second.already_awarded is True
        assert second.xp_earned == first.xp_earned  # original amount, not the new pct

    def test_guest_returns_zero_award_and_does_not_persist(self, xp_service, guest, db_session):
        resp = xp_service.award_xp(
            guest, AwardXpRequest(mission_slug="pattern", score_percentage=100.0)
        )
        assert resp.xp_earned == 0
        assert resp.is_guest is True
        assert db_session.query(QuizResult).count() == 0

    def test_unknown_slug_raises_value_error(self, xp_service, user):
        with pytest.raises(ValueError, match="Unknown mission slug"):
            xp_service.award_xp(
                user, AwardXpRequest(mission_slug="not_a_thing", score_percentage=50.0)
            )

    def test_workshop_prefixed_slug_is_accepted(self, xp_service, user):
        resp = xp_service.award_xp(
            user, AwardXpRequest(mission_slug="workshop_42", score_percentage=90.0)
        )
        assert resp.xp_earned == 50

    def test_score_is_clamped_to_zero_hundred(self, xp_service, user, db_session):
        # Pydantic validators on AwardXpRequest reject out-of-range scores at
        # the API boundary. Call the helper directly to exercise the clamp.
        resp = xp_service.award_for_user(user, "pattern", score_percentage=250.0)
        assert resp.xp_earned == 50
        row = db_session.query(QuizResult).filter_by(user_id=user.id).first()
        assert row.percentage == 100.0


class TestGetUserXp:
    def test_guest_returns_zero_state(self, xp_service, guest):
        resp = xp_service.get_user_xp(guest)
        assert resp.total_xp == 0
        assert resp.rank == 0
        assert resp.total_players == 0
        assert resp.missions == []

    def test_total_xp_sums_all_awards(self, xp_service, user, db_session):
        xp_service.award_for_user(user, "pattern", 90.0)   # 50
        xp_service.award_for_user(user, "vocabulary", 60.0)  # 30
        resp = xp_service.get_user_xp(user)
        assert resp.total_xp == 80
        assert {m.mission_slug for m in resp.missions} == {"pattern", "vocabulary"}

    def test_rank_against_other_users(self, xp_service, user, db_session):
        # A second user with more XP → first user should rank 2.
        other = User(username="bob", email="b@b.com", hashed_password="h", is_guest=False)
        db_session.add(other)
        db_session.commit()
        db_session.refresh(other)
        xp_service.award_for_user(user, "pattern", 60.0)   # 30 xp
        xp_service.award_for_user(other, "pattern", 100.0) # 50 xp

        resp = xp_service.get_user_xp(user)
        assert resp.total_players == 2
        assert resp.rank == 2
