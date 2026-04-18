from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from .schemas import (
    DescribeAnswerResponse,
    DescribeProgressResponse,
    DescribeStartResponse,
)
from .service import get_describe_service

router = APIRouter(prefix="/describe", tags=["Describe Mission"])


@router.get("/start")
async def start_mission() -> DescribeStartResponse:
    """Preload a new 5-round Describe-It mission."""
    return get_describe_service().start_mission()


@router.post("/transcribe")
async def transcribe_audio(
    audio: UploadFile = File(...),
    questionIndex: int = Form(...),
) -> DescribeAnswerResponse:
    """Transcribe uploaded audio and validate it against the round's keywords."""
    service = get_describe_service()

    audio_bytes = await audio.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file.")

    transcription = await service.transcribe_audio(
        audio_bytes,
        audio.filename or "audio.wav",
    )
    return service.validate_round(questionIndex, transcription)


@router.get("/progress")
async def get_progress() -> DescribeProgressResponse:
    """Aggregate progress for the current session."""
    return get_describe_service().get_progress()
