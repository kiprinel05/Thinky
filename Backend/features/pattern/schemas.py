from pydantic import BaseModel
from typing import List, Optional

class PatternItem(BaseModel):
    """An item in the pattern sequence."""
    id: str
    shape: str  # circle, square, triangle, star
    color: str  # hex code or color name

class PatternStartResponse(BaseModel):
    """Response when starting a pattern mission."""
    missionId: int
    sequence: List[PatternItem]  # The visible sequence
    options: List[PatternItem]   # Detailed options for the user to choose from
    difficulty: int
    round: int
    totalRounds: int
    instruction: str

class PatternAnswerRequest(BaseModel):
    selectedOptionId: str

class PatternResultResponse(BaseModel):
    success: bool
    correct: bool
    correctOptionId: str
    message: str
    newDifficulty: int
    completionProgress: float  # 0.0 - 1.0

class PatternProgressResponse(BaseModel):
    completed: int
    total: int
    accuracy: float
    currentDifficulty: int
