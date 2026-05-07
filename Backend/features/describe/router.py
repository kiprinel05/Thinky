from fastapi import APIRouter, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from .schemas import (
    DescribeStartResponse,
    TranscriptionResponse,
    TextDescriptionRequest,
    DescribeProgressResponse,
)
from .service import get_describe_service

router = APIRouter(prefix="/describe", tags=["Describe Mission"])


@router.get("/start")
async def start_mission() -> DescribeStartResponse:
    """Start a new describe mission — get the first image."""
    service = get_describe_service()
    return service.start_mission()


@router.get("/next")
async def next_round() -> DescribeStartResponse:
    """Get the next image for a new round."""
    service = get_describe_service()
    return service.get_next_round()


@router.post("/transcribe")
async def transcribe_audio(audio: UploadFile = File(...)) -> TranscriptionResponse:
    """
    Accept audio file, transcribe via Whisper API, validate against keywords.
    
    Supported formats: wav, mp3, m4a, webm, ogg
    """
    service = get_describe_service()
    
    # Read audio bytes
    audio_bytes = await audio.read()
    
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")
    
    # Transcribe using Whisper
    transcription = await service.transcribe_audio(audio_bytes, audio.filename or "audio.wav")
    
    # Validate against expected keywords
    result = service.validate_transcription(transcription)
    
    return result


@router.post("/submit-text")
async def submit_text(request: TextDescriptionRequest) -> TranscriptionResponse:
    """Accept text description and validate against keywords."""
    service = get_describe_service()

    if not request.text or not request.text.strip():
        raise HTTPException(status_code=400, detail="Empty text description")

    result = service.validate_transcription(request.text.strip())
    return result


@router.get("/progress")
async def get_progress() -> DescribeProgressResponse:
    """Get current mission progress and analytics."""
    service = get_describe_service()
    return service.get_progress()


@router.get("/image/{filename}")
async def get_image(filename: str):
    """Serve a describe mission image."""
    service = get_describe_service()
    image_path = service.get_image_path(filename)
    
    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    
    return FileResponse(image_path, media_type="image/png")
