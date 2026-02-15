from pydantic import BaseModel
from typing import List, Dict, Optional


class VocabImage(BaseModel):
    """An image option for a vocabulary question."""
    id: int
    url: str
    label: str  # What this image actually shows


class VocabQuestion(BaseModel):
    """A single word-image matching question."""
    word: str
    images: List[VocabImage]
    correctImageId: int


class VocabStartResponse(BaseModel):
    """Response when starting the vocabulary mission."""
    missionId: int
    questions: List[VocabQuestion]
    totalQuestions: int
    message: str


class VocabAnswerRequest(BaseModel):
    """User's answer submission for a single question."""
    questionIndex: int
    selectedImageId: int


class VocabAnswerResult(BaseModel):
    """Result for a single question after validation."""
    word: str
    selectedImageId: int
    correctImageId: int
    correct: bool


class VocabAnswerResponse(BaseModel):
    """Response after validating a user's answer."""
    success: bool
    correct: bool
    correctImageId: int
    message: str
    encouragement: str  # Mascot bubble text
    progress: Dict[str, int]  # {"completed": N, "total": M}


class VocabProgressResponse(BaseModel):
    """Overall mission progress and analytics."""
    completed: int
    total: int
    correctCount: int
    accuracy: float
    results: List[VocabAnswerResult]
    incorrectWords: List[str]  # Words to repeat (adaptive hook)
    masteryScore: float  # 0.0 - 1.0
