from pydantic import BaseModel
from typing import List, Dict


class VocabImage(BaseModel):
    """
    An image option for a vocabulary question.

    We don't store/serve binary assets anymore — the "image" is an emoji
    glyph that renders identically on every platform and is trivially
    translatable / easy to recognize for kids aged 7-12.
    """
    id: int
    emoji: str
    # Label used both for accessibility hints and fallback text.
    labelEn: str
    labelRo: str


class VocabQuestion(BaseModel):
    """A single word→image matching question, bilingual."""
    wordEn: str
    wordRo: str
    category: str  # "animal", "food", "object", "nature"
    images: List[VocabImage]
    correctImageId: int


class VocabStartResponse(BaseModel):
    """Response when starting the vocabulary mission."""
    missionId: int
    questions: List[VocabQuestion]
    totalQuestions: int


class VocabAnswerRequest(BaseModel):
    """User's answer submission for a single question."""
    questionIndex: int
    selectedImageId: int


class VocabAnswerResult(BaseModel):
    """Result for a single question after validation."""
    wordEn: str
    wordRo: str
    selectedImageId: int
    correctImageId: int
    correct: bool


class VocabAnswerResponse(BaseModel):
    """Response after validating a user's answer."""
    success: bool
    correct: bool
    correctImageId: int
    progress: Dict[str, int]  # {"completed": N, "total": M}


class VocabProgressResponse(BaseModel):
    """Overall mission progress and analytics."""
    completed: int
    total: int
    correctCount: int
    accuracy: float
    results: List[VocabAnswerResult]
    incorrectWordsEn: List[str]
    masteryScore: float  # 0.0 - 1.0
