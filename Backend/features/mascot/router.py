from fastapi import APIRouter, HTTPException, status
from features.mascot.schemas import MascotChatRequest, MascotChatResponse
from features.mascot.service import get_mascot_service

router = APIRouter(prefix="/ai/mascot", tags=["mascot"])


@router.post("/chat", response_model=MascotChatResponse)
async def mascot_chat(request: MascotChatRequest):
    """Chat with Pixy, the app mascot."""
    if not request.message or not request.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty",
        )

    try:
        service = get_mascot_service()
        reply = await service.chat(
            message=request.message.strip(),
            context=request.context,
        )
        return MascotChatResponse(reply=reply)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(e),
        )
    except Exception as e:
        print(f"[ERROR] Mascot chat error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Mascot service error",
        )
