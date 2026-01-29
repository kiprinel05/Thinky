from typing import List, Dict
from sqlalchemy.orm import Session
from datetime import datetime, timezone

import random

from features.pixy_learns.schemas import LabelSubmission, LearningProgressResponse
from features.mission.repository import MissionRepository
from features.mission.models import Mission, MissionProgress
from core.base.service import BaseService

# Image URLs for cat and apple categories
CAT_IMAGES = [
    "https://placekitten.com/200/200",
    "https://placekitten.com/201/201",
    "https://placekitten.com/202/202",
    "https://placekitten.com/203/203",
    "https://placekitten.com/204/204",
]

APPLE_IMAGES = [
    "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Red_Apple.jpg/200px-Red_Apple.jpg",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Honeycrisp.jpg/200px-Honeycrisp.jpg",
    "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Apples.jpg/200px-Apples.jpg",
]

class PixyLearnsService:
    # Store current session images (in production, use Redis or DB)
    _current_images = {}
    
    def __init__(self, mission_repository: MissionRepository):
        self.mission_repo = mission_repository

    def get_images(self) -> Dict:
        """Generate 6 random images (3 cats, 3 apples) and return them shuffled"""
        images = []
        
        # Generate 3 cat images
        for i in range(3):
            image_id = f"cat_{i}_{random.randint(1000, 9999)}"
            url = random.choice(CAT_IMAGES) + f"?v={random.randint(1, 1000)}"
            images.append({
                "id": image_id,
                "url": url,
                "correct_label": "cat"
            })
            self._current_images[image_id] = "cat"
        
        # Generate 3 apple images
        for i in range(3):
            image_id = f"apple_{i}_{random.randint(1000, 9999)}"
            url = random.choice(APPLE_IMAGES)
            images.append({
                "id": image_id,
                "url": url,
                "correct_label": "apple"
            })
            self._current_images[image_id] = "apple"
        
        # Shuffle the images
        random.shuffle(images)
        
        return {
            "images": [{"id": img["id"], "url": img["url"]} for img in images],
            "total": len(images)
        }

    def process_submission(self, user_id: int, submission: LabelSubmission) -> LearningProgressResponse:
        """Validate user's labels against correct answers"""
        correct_count = 0
        total = len(submission.labels)
        
        for label_request in submission.labels:
            correct_label = self._current_images.get(label_request.image_id)
            if correct_label and label_request.label.lower() == correct_label.lower():
                correct_count += 1
        
        learned_examples = correct_count
        progress_percentage = (learned_examples / total) * 100 if total > 0 else 0
        categories = list(set([label.label.lower() for label in submission.labels]))
        is_complete = learned_examples == total
        
        # Update mission progress if all correct
        if is_complete:
            mission = self.mission_repo.db.query(Mission).filter(Mission.mission_path == "pixy_learns").first()
            if mission:
                self._update_mission_progress(user_id, mission.id, progress_percentage)
        
        # Clear session images after submission
        self._current_images.clear()
                
        return LearningProgressResponse(
            total_examples=total,
            learned_examples=learned_examples,
            categories=categories,
            progress_percentage=progress_percentage,
            is_complete=is_complete
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
            total_examples=6,
            learned_examples=0,
            categories=[],
            progress_percentage=0.0,
            is_complete=False
        )

