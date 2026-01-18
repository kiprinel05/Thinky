from typing import List, Dict
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from features.pixy_learns.schemas import LabelSubmission, LearningProgressResponse
from features.mission.repository import MissionRepository
from features.mission.models import Mission, MissionProgress
from core.base.service import BaseService

# Simulated learning data - in a real app, this would be in a database
# Keeping it here as per legacy behavior but encapsulated in Service
LEARNING_IMAGES = [
    {"id": "apple1", "url": "apple", "category": "apple"},
    {"id": "apple2", "url": "apple", "category": "apple"},
    {"id": "cat1", "url": "cat", "category": "cat"},
    {"id": "cat2", "url": "cat", "category": "cat"},
    {"id": "apple3", "url": "apple", "category": "apple"},
    {"id": "cat3", "url": "cat", "category": "cat"},
]

class PixyLearnsService:
    def __init__(self, mission_repository: MissionRepository):
        self.mission_repo = mission_repository

    def get_images(self) -> Dict:
        return {
            "images": [
                {
                    "id": img["id"],
                    "url": img["url"],
                }
                for img in LEARNING_IMAGES
            ],
            "total": len(LEARNING_IMAGES)
        }

    def process_submission(self, user_id: int, submission: LabelSubmission) -> LearningProgressResponse:
        correct_count = 0
        total = len(LEARNING_IMAGES)
        image_map = {img["id"]: img["category"] for img in LEARNING_IMAGES}
        
        for label_request in submission.labels:
            correct_category = image_map.get(label_request.image_id)
            if correct_category and label_request.label.lower() == correct_category.lower():
                correct_count += 1
        
        learned_examples = correct_count
        progress_percentage = (learned_examples / total) * 100 if total > 0 else 0
        categories = list(set([label.label.lower() for label in submission.labels]))
        
        # Update mission progress if completed
        if learned_examples == total:
            # We assume the mission_path is "pixy_learns" as per old code
            # In a better design, we'd look up mission by context, but hardcoding for migration fidelity
            mission = self.mission_repo.db.query(Mission).filter(Mission.mission_path == "pixy_learns").first()
            if mission:
                self._update_mission_progress(user_id, mission.id, progress_percentage)
                
        return LearningProgressResponse(
            total_examples=total,
            learned_examples=learned_examples,
            categories=categories,
            progress_percentage=progress_percentage
        )

    def _update_mission_progress(self, user_id: int, mission_id: int, score: float):
        existing_progress = self.mission_repo.get_progress_by_mission(user_id, mission_id)
        
        if existing_progress:
            if not existing_progress.is_completed:
                existing_progress.is_completed = True
                existing_progress.completed_at = datetime.now(timezone.utc)
                existing_progress.score = score
                self.mission_repo.db.commit()
        else:
            new_progress = MissionProgress(
                user_id=user_id,
                mission_id=mission_id,
                is_completed=True,
                completed_at=datetime.now(timezone.utc),
                score=score
            )
            self.mission_repo.db.add(new_progress)
            self.mission_repo.db.commit()

    def get_progress(self, user_id: int) -> LearningProgressResponse:
         # Needs real DB implementation in future
         return LearningProgressResponse(
            total_examples=len(LEARNING_IMAGES),
            learned_examples=0,
            categories=[],
            progress_percentage=0.0
        )
