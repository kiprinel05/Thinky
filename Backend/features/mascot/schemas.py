from pydantic import BaseModel
from typing import Optional, Dict, Any


class MascotContext(BaseModel):
    current_page: str = "Unknown"
    installed_missions: int = 0
    created_missions: int = 0
    current_feature: Optional[str] = None


class MascotChatRequest(BaseModel):
    message: str
    context: Optional[MascotContext] = None


class MascotChatResponse(BaseModel):
    reply: str
