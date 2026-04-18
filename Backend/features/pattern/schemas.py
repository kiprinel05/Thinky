"""
Schemas for the Complete-the-Pattern mission.

The backend pre-generates all 5 rounds (emoji-based, bilingual) when the
player starts the mission. The frontend then plays through them locally and
sends each answer back for validation against the stored correct option.
"""
from pydantic import BaseModel
from typing import List


class PatternItem(BaseModel):
    """A single visual step in a pattern sequence.

    Items are rendered as emojis on the client, but we also ship bilingual
    labels for accessibility and the "correct answer" chip in feedback.
    """
    id: int
    emoji: str
    labelEn: str
    labelRo: str


class PatternQuestion(BaseModel):
    """One round of the Complete-the-Pattern mission.

    - `sequence` is the visible pattern (4-7 items) the child sees.
    - `options` is a shuffled list of 3 choices (1 correct + 2 distractors).
    - The correct option id is NOT exposed here; the backend validates via
      `/answer` and only reveals the correct id in the answer response.
    """
    index: int
    theme: str
    rule: str
    difficulty: int
    sequence: List[PatternItem]
    options: List[PatternItem]


class PatternStartResponse(BaseModel):
    """Payload returned on /pattern/start."""
    missionId: int
    totalRounds: int
    questions: List[PatternQuestion]


class PatternAnswerRequest(BaseModel):
    questionIndex: int
    selectedOptionId: int


class PatternProgress(BaseModel):
    completed: int
    total: int


class PatternAnswerResponse(BaseModel):
    success: bool
    correct: bool
    correctOptionId: int
    progress: PatternProgress


class PatternProgressResponse(BaseModel):
    completed: int
    total: int
    correctCount: int
    accuracy: float
