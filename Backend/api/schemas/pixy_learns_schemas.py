from pydantic import BaseModel
from typing import List, Optional

class ImageLabelRequest(BaseModel):
    image_id: str
    label: str

class LearningProgressResponse(BaseModel):
    total_examples: int
    learned_examples: int
    categories: List[str]
    progress_percentage: float

class LabelSubmission(BaseModel):
    labels: List[ImageLabelRequest]



