from pydantic import BaseModel
from typing import Optional, Dict


class DrawingAnalysisResponse(BaseModel):
    """Response model for drawing analysis results."""

    detected_shape: Optional[str] = None
    detected_color: Optional[str] = None
    vertex_count: int = 0

    is_triangle: bool = False
    is_blue: bool = False
    is_circle: bool = False
    is_red: bool = False
    is_correct: bool = False

    confidence_shape: float = 0.0
    confidence_color: float = 0.0
    coverage: float = 0.0

    shape_confidences: Dict[str, float] = {}
    color_confidences: Dict[str, float] = {}
    is_scribble: bool = False
    is_too_small: bool = False

    message: str = ""
    pixy_emotion: str = "neutral"

    class Config:
        from_attributes = True
