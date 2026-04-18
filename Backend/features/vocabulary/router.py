from fastapi import APIRouter, HTTPException

from .schemas import (
    VocabAnswerRequest,
    VocabAnswerResponse,
    VocabProgressResponse,
    VocabStartResponse,
)
from .service import get_vocabulary_service

router = APIRouter(prefix="/vocabulary", tags=["Vocabulary Mission"])


@router.get("/start")
async def start_mission() -> VocabStartResponse:
    """Start a new bilingual word→emoji matching round."""
    return get_vocabulary_service().start_mission()


@router.post("/answer")
async def submit_answer(request: VocabAnswerRequest) -> VocabAnswerResponse:
    """
    Validate a single answer.

    Feedback messages (encouragement, mascot lines, etc.) are built on the
    client from the localized string bundles so we don't need to translate
    them here.
    """
    try:
        return get_vocabulary_service().validate_answer(request)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/progress")
async def get_progress() -> VocabProgressResponse:
    """Current mission progress + analytics."""
    return get_vocabulary_service().get_progress()
