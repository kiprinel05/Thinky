from typing import List, Optional

from pydantic import BaseModel


class LeaderboardMissionPoints(BaseModel):
    """Per-mission XP breakdown for a user row."""

    mission_id: str
    xp: float


class LeaderboardEntry(BaseModel):
    user_id: int
    username: str
    xp: float
    missions_completed: int
    workshop_missions_completed: int
    mission_points: Optional[List[LeaderboardMissionPoints]] = None


class LeaderboardStats(BaseModel):
    total_players: int
    average_xp: float
    max_xp: float
    min_xp: float


class LeaderboardResponse(BaseModel):
    entries: List[LeaderboardEntry]
    stats: LeaderboardStats
