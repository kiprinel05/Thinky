from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

# Support both old (api/) and new (features/) architecture
try:
    from api.dependencies import get_current_user
    from database import get_db
    from models.user_model import User
    from models.mission_model import Mission
except ImportError:
    from core.database import get_db
    from features.auth.dependencies import get_current_user
    from features.auth.models import User
    from features.mission.models import Mission

from features.numbers.schemas import (
    NumbersStartResponse, NumbersRoundResponse,
    CountingSubmission, CountingResponse,
    DrawingResponse, NumbersProgressResponse,
)
from features.numbers.service import NumbersService
from features.mission.repository import MissionRepository

router = APIRouter(prefix="/numbers", tags=["Numbers Mission"])


def get_numbers_service(db: Session = Depends(get_db)) -> NumbersService:
    mission_repo = MissionRepository(Mission, db)
    return NumbersService(mission_repo)


@router.post("/start", response_model=NumbersStartResponse)
async def start_session(
    current_user: User = Depends(get_current_user),
    service: NumbersService = Depends(get_numbers_service),
):
    """Start a new numbers learning session."""
    return service.start_session(current_user.id)


@router.get("/round", response_model=NumbersRoundResponse)
async def get_round(
    current_user: User = Depends(get_current_user),
    service: NumbersService = Depends(get_numbers_service),
):
    """Get the current round data with Pixy's guess."""
    return service.get_round(current_user.id)


@router.post("/submit-count", response_model=CountingResponse)
async def submit_count(
    submission: CountingSubmission,
    current_user: User = Depends(get_current_user),
    service: NumbersService = Depends(get_numbers_service),
):
    """Submit a counting answer for Part 1."""
    return service.submit_count(current_user.id, submission)


@router.post("/submit-drawing", response_model=DrawingResponse)
async def submit_drawing(
    file: UploadFile = File(..., description="PNG or JPG image of the drawn digit"),
    current_user: User = Depends(get_current_user),
    service: NumbersService = Depends(get_numbers_service),
):
    """Submit a digit drawing for Part 2."""
    try:
        if file.content_type not in ["image/png", "image/jpeg", "image/jpg"]:
            raise HTTPException(
                status_code=400,
                detail="Only PNG and JPG images are supported",
            )

        contents = await file.read()

        if len(contents) > 5 * 1024 * 1024:
            raise HTTPException(
                status_code=400,
                detail="Image too large. Maximum size is 5MB.",
            )

        return service.submit_drawing(current_user.id, contents)

    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Drawing submission failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing drawing: {str(e)}",
        )


@router.get("/progress", response_model=NumbersProgressResponse)
async def get_progress(
    current_user: User = Depends(get_current_user),
    service: NumbersService = Depends(get_numbers_service),
):
    """Get current session progress."""
    return service.get_progress(current_user.id)
