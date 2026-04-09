from typing import List, Optional

from pydantic import BaseModel


class LeaderboardMissionPoints(BaseModel):
    """Optional per-mission score for a user row (frontend shows a breakdown when present)."""

    mission_id: str
    points: float


class LeaderboardEntry(BaseModel):
    user_id: int
    username: str
    points: float
    missions_completed: int
    workshop_missions_completed: int
    mission_points: Optional[List[LeaderboardMissionPoints]] = None


class LeaderboardStats(BaseModel):
    total_players: int
    average_points: float
    max_points: float
    min_points: float


class LeaderboardResponse(BaseModel):
    entries: List[LeaderboardEntry]
    stats: LeaderboardStats

