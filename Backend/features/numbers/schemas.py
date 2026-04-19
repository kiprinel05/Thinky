from pydantic import BaseModel
from typing import List, Optional


class ObjectItem(BaseModel):
    """An object displayed for counting (emoji + type)."""
    emoji: str
    object_type: str  # "apple", "balloon", "star"


class NumbersStartResponse(BaseModel):
    """Response when starting a new numbers session."""
    target_number: int
    objects: List[ObjectItem]
    model_level: str  # "junior", "student", "expert"
    current_part: int  # 1 or 2
    message: str


class NumbersRoundResponse(BaseModel):
    """Response for the current round state."""
    target_number: int
    objects: List[ObjectItem]
    pixy_guess: int
    pixy_message: str
    pixy_confidence: str  # "low", "medium", "high"
    model_level: str
    current_part: int


class CountingSubmission(BaseModel):
    """Submission for Part 1 - counting objects."""
    answer: int
    confirmed: bool = False  # True = child confirms Pixy's guess


class CountingResponse(BaseModel):
    """Response after submitting a counting answer."""
    is_correct: bool
    correct_answer: int
    pixy_guess: int
    pixy_message: str
    pixy_emotion: str  # "confused", "thinking", "happy", "sad"
    model_level: str
    correct_count: int
    confusion_count: int
    show_professor: bool
    professor_message: Optional[str] = None
    model_upgraded: bool = False
    new_model_level: Optional[str] = None
    part_completed: bool = False


class DrawingResponse(BaseModel):
    """Response after Pixy looks at a child's free drawing.

    Pixy proposes a guess and a (display) confidence. The UI then asks the
    child whether the guess was right via the /teach-drawing endpoint.
    """
    guessed_digit: Optional[int] = None
    confidence: float = 0.0  # display confidence shown to the child (0.0–1.0)
    pixy_message: str
    pixy_emotion: str
    model_level: str
    examples_taught: int
    awaiting_confirmation: bool = True


class TeachDrawingSubmission(BaseModel):
    """Child confirms or corrects Pixy's last guess."""
    claimed_digit: int  # what the child says they actually drew (0-9)


class TeachDrawingResponse(BaseModel):
    """Response after the child teaches Pixy what the drawing really was."""
    was_pixy_correct: bool      # did Pixy's guess match the claim?
    is_lying: bool              # did the child mis-label a clearly drawn digit?
    claimed_digit: int
    recognized_digit: Optional[int] = None
    pixy_message: str
    pixy_emotion: str
    model_level: str
    correct_count: int
    confusion_count: int
    examples_taught: int
    show_professor: bool
    professor_message: Optional[str] = None
    professor_hint: Optional[str] = None
    model_upgraded: bool = False
    new_model_level: Optional[str] = None
    part_completed: bool = False


class NumbersProgressResponse(BaseModel):
    """Overall progress for the numbers mission."""
    current_part: int
    model_level: str
    correct_count: int
    confusion_count: int
    rounds_completed: int
    is_complete: bool = False
    score: float = 0.0
