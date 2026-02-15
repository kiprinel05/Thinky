from pydantic import BaseModel
from typing import List, Optional


class DescribeImageInfo(BaseModel):
    """Info about the image the user should describe."""
    imageId: str
    imageUrl: str
    expectedKeywords: List[str]
    hint: str  # Optional hint for the user


class DescribeStartResponse(BaseModel):
    """Response when starting the describe mission."""
    missionId: int
    image: DescribeImageInfo
    instruction: str
    round: int
    totalRounds: int


class TranscriptionResponse(BaseModel):
    """Response after transcribing and validating audio."""
    success: bool
    transcription: str
    matchScore: float        # 0.0 - 1.0
    matchedKeywords: List[str]
    missingKeywords: List[str]
    message: str             # User-facing feedback
    encouragement: str       # Mascot bubble text


class DescribeProgressResponse(BaseModel):
    """Overall session progress."""
    completed: int
    total: int
    totalScore: float        # Average match score
    roundResults: List[dict]
