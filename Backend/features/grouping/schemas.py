from pydantic import BaseModel
from typing import List, Dict, Optional


class GroupingItem(BaseModel):
    """Represents an item image to be categorized."""
    id: str
    url: str
    label: str  # Actual category: "fruits", "vegetables", "toys"
    name: str   # Display name: "Apple", "Carrot", etc.


class GroupingStartResponse(BaseModel):
    """Response for starting a grouping mission."""
    current_round: int
    total_rounds: int
    categories: List[str]
    message: str


class GroupingRoundResponse(BaseModel):
    """Response with items to sort for current round."""
    round_number: int
    total_rounds: int
    items: List[GroupingItem]
    categories: List[str]


class GroupingItemResult(BaseModel):
    """Result for a single item's grouping."""
    item_id: str
    item_name: str
    user_category: str
    correct_category: str
    is_correct: bool


class GroupingSubmitRequest(BaseModel):
    """Request to submit user's grouping assignments."""
    assignments: Dict[str, str]  # item_id -> user's chosen category
    time_spent: float  # seconds


class GroupingSubmitResponse(BaseModel):
    """Response with validation results."""
    is_correct: bool  # All items correct
    accuracy: float   # 0.0 - 1.0
    time_spent: float
    correct_count: int
    total_count: int
    details: List[GroupingItemResult]
    message: str
    pixy_emotion: str  # "happy", "encouraging", "thinking"
    difficulty_level: int = 1  # Adaptive difficulty placeholder
