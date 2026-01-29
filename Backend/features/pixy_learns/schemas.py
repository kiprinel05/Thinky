from pydantic import BaseModel
from typing import List

class ImageLabelRequest(BaseModel):
    image_id: str
    label: str

class LabelSubmission(BaseModel):
    labels: List[ImageLabelRequest]

class LearningProgressResponse(BaseModel):
    total_examples: int
    learned_examples: int
    categories: List[str]
    progress_percentage: float
    is_complete: bool = False

