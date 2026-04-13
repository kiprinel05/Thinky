from pydantic import BaseModel, Field


class AwardXpRequest(BaseModel):
    mission_slug: str = Field(..., min_length=1, max_length=50)
    score_percentage: float = Field(..., ge=0.0, le=100.0)


class AwardXpResponse(BaseModel):
    xp_earned: int
    mission_slug: str
    already_awarded: bool
