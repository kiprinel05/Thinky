from collections import defaultdict
from typing import Dict, List, Optional

from sqlalchemy import func as sa_func
from sqlalchemy.orm import Session

from features.auth.models import User
from features.quiz.models import QuizResult
from features.mission.models import MissionProgress
from features.workshop.models import WorkshopDownload
from features.leaderboard.schemas import (
    LeaderboardEntry,
    LeaderboardMissionPoints,
    LeaderboardResponse,
    LeaderboardStats,
)


class LeaderboardService:
    """Compute leaderboard data based on quiz XP."""

    def __init__(self, db: Session):
        self.db = db

    def get_leaderboard(
        self,
        include_workshop: bool = True,
        limit: int = 50,
    ) -> LeaderboardResponse:
        # Aggregate XP from quiz_results per user
        xp_rows = (
            self.db.query(
                QuizResult.user_id,
                sa_func.sum(QuizResult.xp_earned).label("total_xp"),
            )
            .group_by(QuizResult.user_id)
            .all()
        )

        user_xp: Dict[int, float] = {row.user_id: float(row.total_xp) for row in xp_rows}

        # Per-user quiz type breakdown (quiz_type serves as the mission slug)
        breakdown_rows = (
            self.db.query(
                QuizResult.user_id,
                QuizResult.quiz_type,
                sa_func.sum(QuizResult.xp_earned).label("slug_xp"),
            )
            .group_by(QuizResult.user_id, QuizResult.quiz_type)
            .all()
        )

        user_slug_xp: Dict[int, Dict[str, float]] = defaultdict(lambda: defaultdict(float))
        for row in breakdown_rows:
            user_slug_xp[row.user_id][row.quiz_type] = float(row.slug_xp)

        # Count completed missions per user (display-only, no ranking weight)
        mission_progress_rows = (
            self.db.query(
                MissionProgress.user_id,
                sa_func.count(MissionProgress.id).label("cnt"),
            )
            .filter(MissionProgress.is_completed == True)
            .group_by(MissionProgress.user_id)
            .all()
        )
        user_missions_completed: Dict[int, int] = {
            row.user_id: row.cnt for row in mission_progress_rows
        }

        # Count distinct workshop downloads per user (display-only)
        user_workshop_completed: Dict[int, int] = {}
        if include_workshop:
            workshop_rows = (
                self.db.query(
                    WorkshopDownload.user_id,
                    sa_func.count(sa_func.distinct(WorkshopDownload.mission_id)).label("cnt"),
                )
                .group_by(WorkshopDownload.user_id)
                .all()
            )
            user_workshop_completed = {row.user_id: row.cnt for row in workshop_rows}

        # Collect all user IDs that have XP
        user_ids = list(user_xp.keys())
        if not user_ids:
            empty_stats = LeaderboardStats(
                total_players=0,
                average_xp=0.0,
                max_xp=0.0,
                min_xp=0.0,
            )
            return LeaderboardResponse(entries=[], stats=empty_stats)

        users = self.db.query(User).filter(User.id.in_(user_ids)).all()
        username_map = {
            u.id: (u.username or u.guest_name or f"User {u.id}")
            for u in users
        }

        def build_mission_xp_breakdown(uid: int) -> Optional[List[LeaderboardMissionPoints]]:
            combined = dict(user_slug_xp.get(uid, {}))
            if not combined:
                return None
            return [
                LeaderboardMissionPoints(mission_id=slug, xp=xp)
                for slug, xp in sorted(combined.items(), key=lambda x: (-x[1], x[0]))
            ]

        entries: List[LeaderboardEntry] = []
        for uid, xp in user_xp.items():
            entries.append(
                LeaderboardEntry(
                    user_id=uid,
                    username=username_map.get(uid, f"User {uid}"),
                    xp=xp,
                    missions_completed=user_missions_completed.get(uid, 0),
                    workshop_missions_completed=user_workshop_completed.get(uid, 0),
                    mission_points=build_mission_xp_breakdown(uid),
                )
            )

        entries.sort(key=lambda e: (-e.xp, e.username.lower()))

        all_xp_values = [e.xp for e in entries]
        total_players = len(entries)
        average_xp = sum(all_xp_values) / total_players if total_players else 0.0
        max_xp = max(all_xp_values) if all_xp_values else 0.0
        min_xp = min(all_xp_values) if all_xp_values else 0.0

        stats = LeaderboardStats(
            total_players=total_players,
            average_xp=average_xp,
            max_xp=max_xp,
            min_xp=min_xp,
        )

        entries = entries[:limit]

        return LeaderboardResponse(entries=entries, stats=stats)
