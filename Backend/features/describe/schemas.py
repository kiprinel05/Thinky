from pydantic import BaseModel
from typing import List, Optional


class DescribeItem(BaseModel):
    """A single bilingual scene the child describes with their voice."""
    id: int
    emoji: str                  # main emoji, e.g. "🐕"
    secondaryEmoji: str         # accent / context emoji, e.g. "🌳"
    accentHex: str              # hex color for the scene card gradient
    themeEn: str                # "Animal", "Fruit", etc.
    themeRo: str                # "Animal", "Fruct", etc.
    hintEn: str                 # guiding question in English
    hintRo: str                 # guiding question in Romanian
    keywordsEn: List[str]       # words we expect in an English description
    keywordsRo: List[str]       # words we expect in a Romanian description


class DescribeStartResponse(BaseModel):
    """All preloaded rounds for the mission — client-side navigation."""
    missionId: int
    questions: List[DescribeItem]
    totalRounds: int


class TranscriptionRoundResult(BaseModel):
    """Per-round result returned by the backend after transcription."""
    success: bool
    transcription: str
    detectedLang: str           # 'en' | 'ro' | 'mixed'
    matchScore: float           # 0.0 - 1.0 (best of EN/RO)
    matchedKeywords: List[str]  # localized to detected language
    missingKeywords: List[str]  # localized to detected language
    message: str
    encouragement: str


class DescribeAnswerResponse(BaseModel):
    """Response envelope shared with the controller."""
    success: bool
    correct: bool
    result: TranscriptionRoundResult
    completed: int
    total: int


class DescribeProgressResponse(BaseModel):
    """Overall session progress / debugging endpoint."""
    completed: int
    total: int
    correctCount: int
    accuracy: float
    averageScore: float
