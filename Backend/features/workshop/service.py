import json
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_

from features.workshop.models import WorkshopMission, WorkshopDownload
from features.workshop.schemas import (
    WorkshopMissionCreate,
    WorkshopMissionUpdate,
    WorkshopMissionResponse,
    WorkshopMissionDetailResponse,
    WorkshopMissionListResponse,
    WorkshopQuestionCreate,
    WorkshopAnswerCreate,
)

# Support both old (api/) and new (features/) architecture
try:
    from models.user_model import User
except ImportError:
    from features.auth.models import User


class WorkshopService:
    def __init__(self, db: Session):
        self.db = db

    # ──────────────────────────────────────────────────────────────────────
    # BROWSE
    # ──────────────────────────────────────────────────────────────────────

    def get_missions(
        self,
        search: Optional[str] = None,
        tags: Optional[List[str]] = None,
        sort_by: str = "recent",
        page: int = 1,
        limit: int = 20,
    ) -> WorkshopMissionListResponse:
        query = self.db.query(WorkshopMission).filter(WorkshopMission.is_published == True)

        # Search by title or description
        if search:
            pattern = f"%{search}%"
            query = query.filter(
                or_(
                    WorkshopMission.title.ilike(pattern),
                    WorkshopMission.description.ilike(pattern),
                )
            )

        # Filter by tags (any match)
        if tags:
            for tag in tags:
                query = query.filter(WorkshopMission.tags.ilike(f'%"{tag}"%'))

        # Total before pagination
        total = query.count()

        # Sort
        if sort_by == "popular":
            query = query.order_by(WorkshopMission.download_count.desc())
        else:  # recent
            query = query.order_by(WorkshopMission.created_at.desc())

        # Paginate
        offset = (page - 1) * limit
        missions = query.offset(offset).limit(limit).all()

        return WorkshopMissionListResponse(
            missions=[self._to_response(m) for m in missions],
            total=total,
        )

    # ──────────────────────────────────────────────────────────────────────
    # DETAIL
    # ──────────────────────────────────────────────────────────────────────

    def get_mission_detail(self, mission_id: int) -> Optional[WorkshopMissionDetailResponse]:
        mission = self.db.query(WorkshopMission).filter(WorkshopMission.id == mission_id).first()
        if not mission:
            return None
        return self._to_detail_response(mission)

    # ──────────────────────────────────────────────────────────────────────
    # UPLOAD
    # ──────────────────────────────────────────────────────────────────────

    def create_mission(self, user_id: int, data: WorkshopMissionCreate) -> WorkshopMissionResponse:
        # Validate correct_answer_index for each question
        for q in data.questions:
            if q.correct_answer_index >= len(q.answers):
                raise ValueError(
                    f"correct_answer_index ({q.correct_answer_index}) is out of range "
                    f"for question '{q.text}' which has {len(q.answers)} answers"
                )

        quiz_data = json.dumps(
            [q.model_dump() for q in data.questions],
            ensure_ascii=False,
        )

        mission = WorkshopMission(
            title=data.title,
            description=data.description,
            author_id=user_id,
            mission_type=data.mission_type,
            tags=json.dumps(data.tags, ensure_ascii=False),
            quiz_data=quiz_data,
        )

        self.db.add(mission)
        self.db.commit()
        self.db.refresh(mission)

        return self._to_response(mission)

    # ──────────────────────────────────────────────────────────────────────
    # DOWNLOAD
    # ──────────────────────────────────────────────────────────────────────

    def download_mission(self, user_id: int, mission_id: int) -> Optional[WorkshopMissionDetailResponse]:
        mission = self.db.query(WorkshopMission).filter(WorkshopMission.id == mission_id).first()
        if not mission:
            return None

        # Check if already downloaded
        existing = (
            self.db.query(WorkshopDownload)
            .filter(
                WorkshopDownload.user_id == user_id,
                WorkshopDownload.mission_id == mission_id,
            )
            .first()
        )

        if not existing:
            download = WorkshopDownload(user_id=user_id, mission_id=mission_id)
            self.db.add(download)
            mission.download_count += 1
            self.db.commit()
            self.db.refresh(mission)

        return self._to_detail_response(mission)

    # ──────────────────────────────────────────────────────────────────────
    # MY MISSIONS
    # ──────────────────────────────────────────────────────────────────────

    def get_my_missions(self, user_id: int) -> WorkshopMissionListResponse:
        missions = (
            self.db.query(WorkshopMission)
            .filter(WorkshopMission.author_id == user_id)
            .order_by(WorkshopMission.created_at.desc())
            .all()
        )
        return WorkshopMissionListResponse(
            missions=[self._to_response(m) for m in missions],
            total=len(missions),
        )

    # ──────────────────────────────────────────────────────────────────────
    # UPDATE
    # ──────────────────────────────────────────────────────────────────────

    def update_mission(
        self, user_id: int, mission_id: int, data: WorkshopMissionUpdate
    ) -> Optional[WorkshopMissionResponse]:
        mission = self.db.query(WorkshopMission).filter(WorkshopMission.id == mission_id).first()
        if not mission or mission.author_id != user_id:
            return None

        if data.title is not None:
            mission.title = data.title
        if data.description is not None:
            mission.description = data.description
        if data.tags is not None:
            mission.tags = json.dumps(data.tags, ensure_ascii=False)
        if data.questions is not None:
            for q in data.questions:
                if q.correct_answer_index >= len(q.answers):
                    raise ValueError(
                        f"correct_answer_index ({q.correct_answer_index}) out of range for '{q.text}'"
                    )
            mission.quiz_data = json.dumps(
                [q.model_dump() for q in data.questions],
                ensure_ascii=False,
            )
            mission.version += 1

        self.db.commit()
        self.db.refresh(mission)
        return self._to_response(mission)

    # ──────────────────────────────────────────────────────────────────────
    # HELPERS
    # ──────────────────────────────────────────────────────────────────────

    def _get_author_name(self, mission: WorkshopMission) -> str:
        author = self.db.query(User).filter(User.id == mission.author_id).first()
        if author:
            return author.username or author.guest_name or f"User #{author.id}"
        return "Unknown"

    def _parse_tags(self, tags_str: Optional[str]) -> List[str]:
        if not tags_str:
            return []
        try:
            return json.loads(tags_str)
        except (json.JSONDecodeError, TypeError):
            return []

    def _parse_questions(self, quiz_data_str: str) -> List[WorkshopQuestionCreate]:
        try:
            raw = json.loads(quiz_data_str)
            return [
                WorkshopQuestionCreate(
                    text=q["text"],
                    answers=[WorkshopAnswerCreate(text=a["text"]) for a in q["answers"]],
                    correct_answer_index=q["correct_answer_index"],
                )
                for q in raw
            ]
        except (json.JSONDecodeError, KeyError, TypeError):
            return []

    def _to_response(self, mission: WorkshopMission) -> WorkshopMissionResponse:
        return WorkshopMissionResponse(
            id=mission.id,
            title=mission.title,
            description=mission.description,
            author_name=self._get_author_name(mission),
            mission_type=mission.mission_type,
            version=mission.version,
            tags=self._parse_tags(mission.tags),
            download_count=mission.download_count,
            created_at=mission.created_at,
        )

    def _to_detail_response(self, mission: WorkshopMission) -> WorkshopMissionDetailResponse:
        return WorkshopMissionDetailResponse(
            id=mission.id,
            title=mission.title,
            description=mission.description,
            author_name=self._get_author_name(mission),
            mission_type=mission.mission_type,
            version=mission.version,
            tags=self._parse_tags(mission.tags),
            download_count=mission.download_count,
            created_at=mission.created_at,
            questions=self._parse_questions(mission.quiz_data),
        )
