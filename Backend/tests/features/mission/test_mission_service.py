"""Tests for MissionService — uses in-memory SQLite + real Mission rows."""
import pytest

from features.auth.models import User
from features.mission.models import Mission, MissionProgress
from features.mission.repository import MissionRepository
from features.mission.service import MissionService


@pytest.fixture
def service(db_session):
    repo = MissionRepository(Mission, db_session)
    return MissionService(repo)


@pytest.fixture
def user(db_session):
    u = User(username="u", email="u@u.com", hashed_password="h", is_guest=False)
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


def _seed_missions(db_session, n: int = 3):
    """Seed `n` active missions ordered 0..n-1."""
    missions = []
    for i in range(n):
        m = Mission(
            title=f"Mission {i}",
            mission_path=f"/mission/{i}",
            order_index=i,
            is_active=True,
        )
        db_session.add(m)
        missions.append(m)
    db_session.commit()
    for m in missions:
        db_session.refresh(m)
    return missions


class TestGetMissionsForUser:
    def test_anonymous_sees_first_unlocked_rest_locked(self, service, db_session):
        _seed_missions(db_session, n=3)
        resp = service.get_missions_for_user(user_id=None)
        assert len(resp.missions) == 3
        assert resp.missions[0].is_locked is False
        assert resp.missions[1].is_locked is True
        assert resp.missions[2].is_locked is True

    def test_user_with_no_progress_has_only_first_unlocked(self, service, db_session, user):
        _seed_missions(db_session, n=3)
        resp = service.get_missions_for_user(user_id=user.id)
        assert resp.missions[0].is_locked is False
        assert resp.missions[1].is_locked is True

    def test_completing_first_unlocks_second(self, service, db_session, user):
        missions = _seed_missions(db_session, n=3)
        service.complete_mission(user.id, missions[0].id, score=80.0)
        resp = service.get_missions_for_user(user_id=user.id)
        assert resp.missions[0].is_locked is False
        assert resp.missions[1].is_locked is False
        assert resp.missions[2].is_locked is True
        # Progress is reflected on the completed mission.
        assert resp.missions[0].progress is not None
        assert resp.missions[0].progress.is_completed is True
        assert resp.missions[0].progress.score == 80.0


class TestCompleteMission:
    def test_first_completion_creates_progress(self, service, db_session, user):
        missions = _seed_missions(db_session, n=1)
        progress = service.complete_mission(user.id, missions[0].id, score=90.0)
        assert progress.is_completed is True
        assert progress.score == 90.0
        rows = db_session.query(MissionProgress).filter_by(user_id=user.id).all()
        assert len(rows) == 1

    def test_second_completion_does_not_create_duplicate(self, service, db_session, user):
        missions = _seed_missions(db_session, n=1)
        service.complete_mission(user.id, missions[0].id, score=70.0)
        service.complete_mission(user.id, missions[0].id, score=100.0)
        rows = db_session.query(MissionProgress).filter_by(user_id=user.id).all()
        assert len(rows) == 1

    def test_completing_missing_mission_raises(self, service, db_session, user):
        with pytest.raises(ValueError, match="Mission not found"):
            service.complete_mission(user.id, mission_id=999, score=50.0)

    def test_completing_locked_mission_raises(self, service, db_session, user):
        missions = _seed_missions(db_session, n=2)
        with pytest.raises(PermissionError, match="Previous mission"):
            service.complete_mission(user.id, missions[1].id, score=50.0)


class TestGetUserProgressList:
    def test_returns_all_progress_rows(self, service, db_session, user):
        missions = _seed_missions(db_session, n=2)
        service.complete_mission(user.id, missions[0].id, score=70.0)
        service.complete_mission(user.id, missions[1].id, score=90.0)
        rows = service.get_user_progress_list(user.id)
        assert len(rows) == 2
        assert all(r.is_completed for r in rows)
