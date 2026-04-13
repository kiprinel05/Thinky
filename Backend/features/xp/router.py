from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.database import get_db
from features.auth.dependencies import get_current_user
from features.auth.models import User
from features.xp.schemas import AwardXpRequest, AwardXpResponse, UserXpResponse
from features.xp.service import XpService

router = APIRouter(prefix="/xp", tags=["XP"])


def get_xp_service(db: Session = Depends(get_db)) -> XpService:
    return XpService(db)


@router.get("/me", response_model=UserXpResponse)
async def get_my_xp(
    current_user: User = Depends(get_current_user),
    service: XpService = Depends(get_xp_service),
) -> UserXpResponse:
    return service.get_user_xp(current_user.id)


@router.post("/award", response_model=AwardXpResponse)
async def award_xp(
    request: AwardXpRequest,
    current_user: User = Depends(get_current_user),
    service: XpService = Depends(get_xp_service),
) -> AwardXpResponse:
    try:
        return service.award_xp(current_user.id, request)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
