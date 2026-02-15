from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from .schemas import (
    VocabStartResponse,
    VocabAnswerRequest,
    VocabAnswerResponse,
    VocabProgressResponse,
)
from .service import get_vocabulary_service

router = APIRouter(prefix="/vocabulary", tags=["Vocabulary Mission"])


@router.get("/start")
async def start_mission() -> VocabStartResponse:
    """Start a new vocabulary matching mission."""
    service = get_vocabulary_service()
    return service.start_mission()


@router.post("/answer")
async def submit_answer(request: VocabAnswerRequest) -> VocabAnswerResponse:
    """
    Submit an answer for a single question.
    
    Validates the user's selected image against the correct answer.
    Returns feedback and updated progress.
    """
    service = get_vocabulary_service()
    
    try:
        return service.validate_answer(
            question_index=request.questionIndex,
            selected_image_id=request.selectedImageId,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/progress")
async def get_progress() -> VocabProgressResponse:
    """Get current mission progress, accuracy, and analytics."""
    service = get_vocabulary_service()
    return service.get_progress()


@router.get("/image/{filename}")
async def get_image(filename: str):
    """Serve a vocabulary item image."""
    service = get_vocabulary_service()
    image_path = service.get_image_path(filename)
    
    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    
    return FileResponse(image_path, media_type="image/png")
