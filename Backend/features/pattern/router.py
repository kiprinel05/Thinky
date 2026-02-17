from fastapi import APIRouter, HTTPException
from .schemas import (
    PatternStartResponse,
    PatternAnswerRequest,
    PatternResultResponse,
    PatternProgressResponse,
)
from .service import get_pattern_service

router = APIRouter(prefix="/pattern", tags=["Pattern Mission"])

@router.get("/start")
async def start_mission() -> PatternStartResponse:
    """Start a new pattern mission."""
    service = get_pattern_service()
    return service.start_mission()

@router.get("/next")
async def next_round() -> PatternStartResponse:
    """Get the next round."""
    service = get_pattern_service()
    return service.get_next_round()

@router.post("/answer")
async def submit_answer(request: PatternAnswerRequest) -> PatternResultResponse:
    """Submit an answer to the current pattern."""
    service = get_pattern_service()
    return service.validate_answer(request.selectedOptionId)

@router.get("/progress")
async def get_progress() -> PatternProgressResponse:
    """Get current mission progress."""
    service = get_pattern_service()
    return service.get_progress()
