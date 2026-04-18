from fastapi import APIRouter

from .schemas import (
    PatternAnswerRequest,
    PatternAnswerResponse,
    PatternProgressResponse,
    PatternStartResponse,
)
from .service import get_pattern_service

router = APIRouter(prefix="/pattern", tags=["Pattern Mission"])


@router.get("/start")
async def start_mission() -> PatternStartResponse:
    """Start a fresh run — returns all rounds pre-generated."""
    service = get_pattern_service()
    return service.start_mission()


@router.post("/answer")
async def submit_answer(request: PatternAnswerRequest) -> PatternAnswerResponse:
    """Validate the player's pick for a specific round."""
    service = get_pattern_service()
    return service.validate_answer(
        question_index=request.questionIndex,
        selected_option_id=request.selectedOptionId,
    )


@router.get("/progress")
async def get_progress() -> PatternProgressResponse:
    service = get_pattern_service()
    return service.get_progress()
