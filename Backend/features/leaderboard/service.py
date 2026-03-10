from collections import defaultdict
from typing import Dict, List

from sqlalchemy.orm import Session

from features.auth.models import User
from features.mission.models import Mission, MissionProgress
from features.workshop.models import WorkshopDownload
from features.leaderboard.schemas import (
    LeaderboardEntry,
    LeaderboardResponse,
    LeaderboardStats,
)


class LeaderboardService:
    """Compute leaderboard data based on missions and workshop downloads."""

    def __init__(self, db: Session):
        self.db = db

    def _get_mission_points(self) -> Dict[int, float]:
        """
        Returns a mapping mission_id -> points.

        For now, each core mission is worth 1 point. This can be extended later
        by adding a `points` column on the Mission model and reading it here.
        """
        missions = self.db.query(Mission.id).filter(Mission.is_active == True).all()
        return {m.id: 1.0 for m in missions}

    def get_leaderboard(
        self,
        include_workshop: bool = True,
        limit: int = 50,
    ) -> LeaderboardResponse:
        mission_points_map = self._get_mission_points()

        # Aggregate mission progress (completed missions only)
        mission_progress_rows: List[MissionProgress] = (
            self.db.query(MissionProgress)
            .filter(MissionProgress.is_completed == True)
            .all()
        )

        user_points: Dict[int, float] = defaultdict(float)
        user_missions_completed: Dict[int, int] = defaultdict(int)
        user_workshop_completed: Dict[int, int] = defaultdict(int)

        for p in mission_progress_rows:
            pts = mission_points_map.get(p.mission_id, 1.0)
            user_points[p.user_id] += pts
            user_missions_completed[p.user_id] += 1

        # Each distinct downloaded workshop mission counts as 1 point
        if include_workshop:
            workshop_rows: List[WorkshopDownload] = (
                self.db.query(WorkshopDownload).all()
            )

            seen_user_mission = set()
            for download in workshop_rows:
                key = (download.user_id, download.mission_id)
                if key in seen_user_mission:
                    continue
                seen_user_mission.add(key)
                user_points[download.user_id] += 1.0
                user_workshop_completed[download.user_id] += 1

        # Load usernames only for users that have any points
        user_ids = list(user_points.keys())
        if not user_ids:
            empty_stats = LeaderboardStats(
                total_players=0,
                average_points=0.0,
                max_points=0.0,
                min_points=0.0,
            )
            return LeaderboardResponse(entries=[], stats=empty_stats)

        users = (
            self.db.query(User)
            .filter(User.id.in_(user_ids))
            .all()
        )
        # Guest users may have username=None; use guest_name or fallback
        username_map = {
            u.id: (u.username or u.guest_name or f"User {u.id}")
            for u in users
        }

        entries: List[LeaderboardEntry] = []
        for user_id, points in user_points.items():
            entries.append(
                LeaderboardEntry(
                    user_id=user_id,
                    username=username_map.get(user_id, f"User {user_id}"),
                    points=points,
                    missions_completed=user_missions_completed[user_id],
                    workshop_missions_completed=user_workshop_completed[user_id],
                )
            )

        # Sort by points desc, then username asc for stable ordering
        entries.sort(key=lambda e: (-e.points, e.username.lower()))
        entries = entries[:limit]

        point_values = [e.points for e in entries]
        total_players = len(entries)
        average_points = sum(point_values) / total_players if total_players else 0.0
        max_points = max(point_values) if point_values else 0.0
        min_points = min(point_values) if point_values else 0.0

        stats = LeaderboardStats(
            total_players=total_players,
            average_points=average_points,
            max_points=max_points,
            min_points=min_points,
        )

        return LeaderboardResponse(entries=entries, stats=stats)

