from pydantic import BaseModel
from typing import Optional


class DrawingAnalysisResponse(BaseModel):
    """Response model for drawing analysis results."""
    
    detected_shape: Optional[str] = None  # "triangle", "square", "circle", "unknown"
    detected_color: Optional[str] = None  # "blue", "red", "green", etc.
    vertex_count: int = 0  # Number of detected vertices
    
    is_triangle: bool = False
    is_blue: bool = False
    is_circle: bool = False
    is_red: bool = False
    is_correct: bool = False  # Both shape and color match target
    
    confidence_shape: float = 0.0  # 0.0 - 1.0
    confidence_color: float = 0.0  # 0.0 - 1.0
    coverage: float = 0.0  # 0.0 - 1.0, how much of the canvas is drawn on
    
    message: str = ""  # User-friendly feedback message
    pixy_emotion: str = "neutral"  # "thinking", "happy", "encouraging", "hint_color"
    
    class Config:
        from_attributes = True
