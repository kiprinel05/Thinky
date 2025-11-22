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

# Simulated learning data - in a real app, this would be in a database
LEARNING_IMAGES = [
    {"id": "apple1", "url": "apple", "category": "apple"},
    {"id": "apple2", "url": "apple", "category": "apple"},
    {"id": "cat1", "url": "cat", "category": "cat"},
    {"id": "cat2", "url": "cat", "category": "cat"},
    {"id": "apple3", "url": "apple", "category": "apple"},
    {"id": "cat3", "url": "cat", "category": "cat"},
]

@router.get("/images")
async def get_learning_images():
    """Get images for labeling"""
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

@router.post("/label", response_model=LearningProgressResponse)
async def submit_labels(
    submission: LabelSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit labeled images and get learning progress"""
    # Count correct labels
    correct_count = 0
    total = len(LEARNING_IMAGES)
    
    # Create a map of image_id -> correct_category
    image_map = {img["id"]: img["category"] for img in LEARNING_IMAGES}
    
    # Count correct labels
    for label_request in submission.labels:
        correct_category = image_map.get(label_request.image_id)
        if correct_category and label_request.label.lower() == correct_category.lower():
            correct_count += 1
    
    learned_examples = correct_count
    progress_percentage = (learned_examples / total) * 100 if total > 0 else 0
    
    # Get unique categories from labels
    categories = list(set([label.label.lower() for label in submission.labels]))
    
    # Mark mission as completed if all images are correctly labeled
    if learned_examples == total:
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

