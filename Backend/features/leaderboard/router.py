from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

try:
    from database import get_db  # type: ignore
except ImportError:  # pragma: no cover - new features/ style
    from core.database import get_db

from features.auth.dependencies import get_current_user_optional
from features.auth.models import User
from features.leaderboard.schemas import LeaderboardResponse
from features.leaderboard.service import LeaderboardService

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])


def get_leaderboard_service(db: Session = Depends(get_db)) -> LeaderboardService:
    return LeaderboardService(db)


@router.get("", response_model=LeaderboardResponse)
async def get_leaderboard(
    include_workshop: bool = Query(
        True,
        description="Include workshop download counts in the response",
    ),
    limit: int = Query(
        20,
        ge=1,
        le=200,
        description="How many top players to display (stats include all players)",
    ),
    current_user: Optional[User] = Depends(get_current_user_optional),
    service: LeaderboardService = Depends(get_leaderboard_service),
) -> LeaderboardResponse:
    """
    Returns the global leaderboard ranked by total XP.

    XP is earned from quiz completions using a tiered formula:
    - Score < 50%  -> 10 XP
    - Score 50-79% -> 30 XP
    - Score >= 80% -> 50 XP
    """

    return service.get_leaderboard(include_workshop=include_workshop, limit=limit)
