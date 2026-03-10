from typing import List

from pydantic import BaseModel


class LeaderboardEntry(BaseModel):
    user_id: int
    username: str
    points: float
    missions_completed: int
    workshop_missions_completed: int


class LeaderboardStats(BaseModel):
    total_players: int
    average_points: float
    max_points: float
    min_points: float


class LeaderboardResponse(BaseModel):
    entries: List[LeaderboardEntry]
    stats: LeaderboardStats

