from pydantic import BaseModel
from typing import List, Optional


class AnimalImage(BaseModel):
    """Represents an animal image with metadata."""
    id: str
    url: str
    label: str  # Actual animal type (cat, dog, elephant, horse, chicken)


class RoundResponse(BaseModel):
    """Response for getting current round image."""
    round_number: int
    total_rounds: int
    image: AnimalImage


class GuessRequest(BaseModel):
    """Request for Pixy to guess the animal."""
    image_id: str


class GuessResponse(BaseModel):
    """Response with Pixy's guess."""
    guess: str  # Pixy's guess
    confidence: float  # How confident Pixy is (0.0 - 1.0)
    actual_animal: str  # The real answer
    is_correct: bool


class VerifyGuessRequest(BaseModel):
    """Request to verify user's confirmation of Pixy's guess."""
    image_id: str
    pixy_guess: str
    user_says_correct: bool


class VerifyGuessResponse(BaseModel):
    """Response for guess verification."""
    was_actually_correct: bool
    user_was_right: bool  # Did user correctly verify?
    message: str


class TeachingImagesResponse(BaseModel):
    """Response with images for teaching phase."""
    target_animal: str
    images: List[AnimalImage]
    correct_image_ids: List[str]  # IDs of images that are the target animal


class ValidateTeachingRequest(BaseModel):
    """Request to validate user's teaching selections."""
    target_animal: str
    selected_image_ids: List[str]


class ValidateTeachingResponse(BaseModel):
    """Response for teaching validation."""
    is_correct: bool
    correct_count: int
    total_correct: int
    missed_count: int
    wrong_count: int
    message: str


class MissionProgressResponse(BaseModel):
    """Overall mission progress."""
    current_round: int
    total_rounds: int
    completed_rounds: int
    pixy_accuracy: float  # How accurate Pixy has been
    is_complete: bool
