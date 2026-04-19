from typing import List, Literal, Optional

from pydantic import BaseModel, Field


class MascotContext(BaseModel):
    """Lightweight snapshot of the user's app state, sent on every message."""

    current_page: str = "Unknown"
    installed_missions: int = 0
    created_missions: int = 0
    current_feature: Optional[str] = None


class MascotChatRequest(BaseModel):
    message: str
    context: Optional[MascotContext] = None
    # Stable per-conversation id chosen by the client. Used by the backend to
    # keep a short rolling history so Pixy can answer follow-up questions.
    # When omitted, the message is treated as a one-off (no history).
    session_id: Optional[str] = Field(default=None, max_length=80)


class MascotChatResponse(BaseModel):
    reply: str
    # Echoed back so the client can confirm which session the reply belongs to
    # (handy if the client rotates session ids on "Clear chat").
    session_id: Optional[str] = None


class MascotResetResponse(BaseModel):
    ok: Literal[True] = True
    session_id: Optional[str] = None
