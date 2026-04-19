from typing import Optional

from fastapi import APIRouter, Header, HTTPException, status

from features.mascot.schemas import (
    MascotChatRequest,
    MascotChatResponse,
    MascotResetResponse,
)
from features.mascot.service import ERROR_REPLIES, get_mascot_service

router = APIRouter(prefix="/ai/mascot", tags=["mascot"])


def _norm_lang(raw: Optional[str]) -> str:
    if not raw:
        return "en"
    code = raw.strip().lower()[:2]
    return code if code in ("en", "ro") else "en"


@router.post("/chat", response_model=MascotChatResponse)
async def mascot_chat(
    request: MascotChatRequest,
    accept_language: Optional[str] = Header(default=None),
):
    """Chat with Pixy, the in-app AI assistant.

    The ``Accept-Language`` header is honored ("en"/"ro"); the system prompt
    and any fallback replies adapt accordingly. ``session_id`` lets the
    backend keep a short rolling history per conversation so Pixy can answer
    follow-up questions coherently.
    """
    lang = _norm_lang(accept_language)

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
            lang=lang,
            session_id=request.session_id,
        )
        return MascotChatResponse(reply=reply, session_id=request.session_id)
    except ValueError:
        # OPENAI_API_KEY missing → degraded mode. Return a localized error
        # body instead of a 503 so the chat UI stays usable.
        return MascotChatResponse(
            reply=ERROR_REPLIES.get(lang, ERROR_REPLIES["en"]),
            session_id=request.session_id,
        )
    except Exception as e:
        print(f"[ERROR] Mascot chat error: {e}")
        return MascotChatResponse(
            reply=ERROR_REPLIES.get(lang, ERROR_REPLIES["en"]),
            session_id=request.session_id,
        )


@router.post("/reset", response_model=MascotResetResponse)
async def mascot_reset(session_id: Optional[str] = None):
    """Wipe Pixy's memory of a conversation. Idempotent."""
    try:
        get_mascot_service().reset(session_id)
    except ValueError:
        # Service couldn't initialize (no API key) — nothing to reset, just OK.
        pass
    return MascotResetResponse(session_id=session_id)
