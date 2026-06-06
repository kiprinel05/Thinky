"""Tests for WorkshopService — DB-backed, uses in-memory SQLite."""
import pytest

from features.auth.models import User
from features.workshop.models import WorkshopDownload, WorkshopMission
from features.workshop.schemas import (
    WorkshopAnswerCreate,
    WorkshopMissionCreate,
    WorkshopMissionUpdate,
    WorkshopQuestionCreate,
)
from features.workshop.service import WorkshopService


@pytest.fixture
def service(db_session):
    return WorkshopService(db_session)


@pytest.fixture
def author(db_session):
    u = User(username="author", email="a@a.com", hashed_password="h", is_guest=False)
    db_session.add(u)
    db_session.commit()
    db_session.refresh(u)
    return u


def _question(text="Q?", n_answers=2, correct_idx=0):
    return WorkshopQuestionCreate(
        text=text,
        answers=[WorkshopAnswerCreate(text=f"A{i}") for i in range(n_answers)],
        correct_answer_index=correct_idx,
    )


def _mission_create(title="My Mission"):
    return WorkshopMissionCreate(
        title=title,
        description="desc",
        tags=["fun", "geo"],
        questions=[_question(), _question("Q2")],
    )


class TestCreateMission:
    def test_create_persists_and_returns_response(self, service, author, db_session):
        resp = service.create_mission(author.id, _mission_create())
        assert resp.title == "My Mission"
        assert resp.author_name == "author"
        assert resp.tags == ["fun", "geo"]
        # Persisted with quiz_data as JSON.
        row = db_session.query(WorkshopMission).first()
        assert row.title == "My Mission"
        assert row.author_id == author.id

    def test_create_with_invalid_correct_index_raises(self, service, author):
        data = WorkshopMissionCreate(
            title="Bad",
            tags=[],
            questions=[_question(n_answers=2, correct_idx=5)],
        )
        with pytest.raises(ValueError, match="out of range"):
            service.create_mission(author.id, data)


class TestSchemaValidation:
    def test_title_too_short_raises_at_pydantic_level(self):
        with pytest.raises(Exception):
            WorkshopMissionCreate(
                title="ab",
                tags=[],
                questions=[_question()],
            )

    def test_question_with_too_few_answers_raises(self):
        with pytest.raises(Exception):
            _question(n_answers=1, correct_idx=0)

    def test_empty_questions_list_raises(self):
        with pytest.raises(Exception):
            WorkshopMissionCreate(title="OK title", tags=[], questions=[])


class TestGetMissions:
    def test_returns_only_published(self, service, author, db_session):
        # Create one published + one unpublished.
        service.create_mission(author.id, _mission_create("Published"))
        # Insert unpublished manually.
        hidden = WorkshopMission(
            title="Hidden",
            author_id=author.id,
            mission_type="quiz",
            is_published=False,
            quiz_data="[]",
        )
        db_session.add(hidden)
        db_session.commit()

        resp = service.get_missions()
        titles = [m.title for m in resp.missions]
        assert "Published" in titles
        assert "Hidden" not in titles

    def test_search_filters_by_title(self, service, author):
        service.create_mission(author.id, _mission_create("Apple Mission"))
        service.create_mission(author.id, _mission_create("Banana Mission"))
        resp = service.get_missions(search="Apple")
        assert resp.total == 1
        assert resp.missions[0].title == "Apple Mission"


class TestDetailAndDownload:
    def test_detail_returns_questions(self, service, author):
        created = service.create_mission(author.id, _mission_create())
        detail = service.get_mission_detail(created.id)
        assert detail is not None
        assert len(detail.questions) == 2

    def test_detail_missing_returns_none(self, service):
        assert service.get_mission_detail(999) is None

    def test_download_creates_download_row_and_increments_count(self, service, author, db_session):
        created = service.create_mission(author.id, _mission_create())
        # Different user downloads.
        downloader = User(username="d", email="d@d.com", hashed_password="h", is_guest=False)
        db_session.add(downloader)
        db_session.commit()
        db_session.refresh(downloader)

        service.download_mission(downloader.id, created.id)
        # Counts should reflect the download.
        row = db_session.query(WorkshopMission).filter_by(id=created.id).first()
        assert row.download_count == 1
        assert db_session.query(WorkshopDownload).count() == 1

    def test_download_twice_does_not_inflate_count(self, service, author, db_session):
        created = service.create_mission(author.id, _mission_create())
        downloader = User(username="d", email="d@d.com", hashed_password="h", is_guest=False)
        db_session.add(downloader)
        db_session.commit()
        db_session.refresh(downloader)

        service.download_mission(downloader.id, created.id)
        service.download_mission(downloader.id, created.id)
        row = db_session.query(WorkshopMission).filter_by(id=created.id).first()
        assert row.download_count == 1


class TestUpdateAndVerify:
    def test_update_by_non_author_returns_none(self, service, author, db_session):
        created = service.create_mission(author.id, _mission_create())
        other = User(username="o", email="o@o.com", hashed_password="h", is_guest=False)
        db_session.add(other)
        db_session.commit()
        db_session.refresh(other)

        resp = service.update_mission(other.id, created.id, WorkshopMissionUpdate(title="Hacked"))
        assert resp is None

    def test_update_by_author_changes_title(self, service, author):
        created = service.create_mission(author.id, _mission_create())
        resp = service.update_mission(author.id, created.id, WorkshopMissionUpdate(title="Renamed"))
        assert resp.title == "Renamed"

    def test_set_verified_toggles_flag(self, service, author):
        created = service.create_mission(author.id, _mission_create())
        resp = service.set_mission_verified(created.id, True)
        assert resp.is_verified is True
        assert resp.verified_at is not None
        resp2 = service.set_mission_verified(created.id, False)
        assert resp2.is_verified is False
        assert resp2.verified_at is None
