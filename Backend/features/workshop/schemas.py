from pydantic import BaseModel, field_validator
from typing import List, Optional
from datetime import datetime


# ══════════════════════════════════════════════════════════════════════════════
# INPUT SCHEMAS
# ══════════════════════════════════════════════════════════════════════════════

class WorkshopAnswerCreate(BaseModel):
    text: str


class WorkshopQuestionCreate(BaseModel):
    text: str
    answers: List[WorkshopAnswerCreate]
    correct_answer_index: int

    @field_validator("answers")
    @classmethod
    def validate_answers(cls, v):
        if len(v) < 2:
            raise ValueError("Each question must have at least 2 answers")
        if len(v) > 6:
            raise ValueError("Each question can have at most 6 answers")
        return v

    @field_validator("correct_answer_index")
    @classmethod
    def validate_correct_index(cls, v, info):
        # Will be validated further in service with answer count
        if v < 0:
            raise ValueError("correct_answer_index must be >= 0")
        return v


class WorkshopMissionCreate(BaseModel):
    title: str
    description: Optional[str] = None
    mission_type: str = "quiz"
    tags: List[str] = []
    questions: List[WorkshopQuestionCreate]

    @field_validator("title")
    @classmethod
    def validate_title(cls, v):
        if len(v.strip()) < 3:
            raise ValueError("Title must be at least 3 characters")
        if len(v) > 200:
            raise ValueError("Title must be at most 200 characters")
        return v.strip()

    @field_validator("questions")
    @classmethod
    def validate_questions(cls, v):
        if len(v) < 1:
            raise ValueError("Must have at least 1 question")
        if len(v) > 50:
            raise ValueError("Cannot exceed 50 questions")
        return v


class WorkshopMissionUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    tags: Optional[List[str]] = None
    questions: Optional[List[WorkshopQuestionCreate]] = None


# ══════════════════════════════════════════════════════════════════════════════
# OUTPUT SCHEMAS
# ══════════════════════════════════════════════════════════════════════════════

class WorkshopMissionResponse(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    author_name: str
    mission_type: str
    version: int
    tags: List[str]
    download_count: int
    created_at: datetime

    class Config:
        from_attributes = True


class WorkshopMissionDetailResponse(WorkshopMissionResponse):
    questions: List[WorkshopQuestionCreate]


class WorkshopMissionListResponse(BaseModel):
    missions: List[WorkshopMissionResponse]
    total: int
