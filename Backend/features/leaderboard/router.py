from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

try:
    # Old api/ style
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
        description="Include points from Workshop missions (downloads)",
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
    Returns the global leaderboard.

    - Each completed core mission = 1 point.
    - Each downloaded Workshop mission = 1 point (when `include_workshop=true`).
    """

    # `current_user` is currently unused but kept for future personalization
    return service.get_leaderboard(include_workshop=include_workshop, limit=limit)

