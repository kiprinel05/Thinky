from typing import List, Optional

from pydantic import BaseModel, Field


class AwardXpRequest(BaseModel):
    mission_slug: str = Field(..., min_length=1, max_length=50)
    score_percentage: float = Field(..., ge=0.0, le=100.0)


class AwardXpResponse(BaseModel):
    xp_earned: int
    mission_slug: str
    already_awarded: bool
    # True when the request came from a guest account. Guests cannot earn XP
    # — the frontend can use this flag to nudge them to create an account.
    is_guest: bool = False


class MissionXpDetail(BaseModel):
    mission_slug: str
    xp: int


class UserXpResponse(BaseModel):
    total_xp: int
    rank: int
    total_players: int
    missions: List[MissionXpDetail] = []
