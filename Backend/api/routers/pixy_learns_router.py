from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from database import get_db
from models.user_model import User
from models.mission_model import MissionProgress, Mission
from api.schemas.pixy_learns_schemas import (
    LabelSubmission,
    LearningProgressResponse,
    ImageLabelRequest
)
from api.dependencies import get_current_user
from datetime import datetime

router = APIRouter(prefix="/pixy-learns", tags=["Pixy Learns"])

import random

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

# Store current session images for validation
_current_images = {}

@router.get("/images")
async def get_learning_images():
    """Get random images for labeling"""
    global _current_images
    _current_images.clear()
    images = []
    
    # Generate 3 cat images
    for i in range(3):
        image_id = f"cat_{i}_{random.randint(1000, 9999)}"
        url = random.choice(CAT_IMAGES) + f"?v={random.randint(1, 1000)}"
        images.append({"id": image_id, "url": url})
        _current_images[image_id] = "cat"
    
    # Generate 3 apple images
    for i in range(3):
        image_id = f"apple_{i}_{random.randint(1000, 9999)}"
        url = random.choice(APPLE_IMAGES)
        images.append({"id": image_id, "url": url})
        _current_images[image_id] = "apple"
    
    # Shuffle
    random.shuffle(images)
    
    return {"images": images, "total": len(images)}

@router.post("/upload", response_model=LearningProgressResponse)
async def submit_labels(
    submission: LabelSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit labeled images and get learning progress"""
    global _current_images
    
    # Count correct labels using stored session images
    correct_count = 0
    total = len(submission.labels)
    
    for label_request in submission.labels:
        correct_label = _current_images.get(label_request.image_id)
        if correct_label and label_request.label.lower() == correct_label.lower():
            correct_count += 1
    
    learned_examples = correct_count
    progress_percentage = (learned_examples / total) * 100 if total > 0 else 0
    
    # Get unique categories from labels
    categories = list(set([label.label.lower() for label in submission.labels]))
    is_complete = learned_examples == total
    
    # Mark mission as completed if all images are correctly labeled
    if is_complete:
        # Find the pixy_learns mission
        mission = db.query(Mission).filter(Mission.mission_path == "pixy_learns").first()
        if mission:
            # Check if already completed
            existing_progress = db.query(MissionProgress).filter(
                MissionProgress.user_id == current_user.id,
                MissionProgress.mission_id == mission.id
            ).first()
            
            if not existing_progress or not existing_progress.is_completed:
                if existing_progress:
                    existing_progress.is_completed = True
                    existing_progress.completed_at = datetime.utcnow()
                    existing_progress.score = progress_percentage
                else:
                    new_progress = MissionProgress(
                        user_id=current_user.id,
                        mission_id=mission.id,
                        is_completed=True,
                        completed_at=datetime.utcnow(),
                        score=progress_percentage
                    )
                    db.add(new_progress)
                db.commit()
    
    return LearningProgressResponse(
        total_examples=total,
        learned_examples=learned_examples,
        categories=categories,
        progress_percentage=progress_percentage
    )

@router.get("/progress", response_model=LearningProgressResponse)
async def get_learning_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current learning progress"""
    # In a real app, this would query the database for user's labeled images
    # For now, return default values
    return LearningProgressResponse(
        total_examples=len(LEARNING_IMAGES),
        learned_examples=0,
        categories=[],
        progress_percentage=0.0
    )

