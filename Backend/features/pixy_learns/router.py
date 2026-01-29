from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from core.database import get_db
from features.auth.dependencies import get_current_user
from features.auth.models import User
from features.pixy_learns.schemas import LabelSubmission, LearningProgressResponse
from features.pixy_learns.service import PixyLearnsService
from features.mission.repository import MissionRepository
from features.mission.models import Mission

router = APIRouter(prefix="/pixy-learns", tags=["Pixy Learns"])

def get_pixy_learns_service(db: Session = Depends(get_db)) -> PixyLearnsService:
    mission_repo = MissionRepository(Mission, db)
    return PixyLearnsService(mission_repo)

@router.get("/images")
async def get_learning_images(service: PixyLearnsService = Depends(get_pixy_learns_service)):
    return service.get_images()

@router.post("/upload", response_model=LearningProgressResponse)
async def submit_labels(
    submission: LabelSubmission,
    current_user: User = Depends(get_current_user),
    service: PixyLearnsService = Depends(get_pixy_learns_service)
):
    return service.process_submission(current_user.id, submission)

@router.get("/progress", response_model=LearningProgressResponse)
async def get_learning_progress(
    current_user: User = Depends(get_current_user),
    service: PixyLearnsService = Depends(get_pixy_learns_service)
):
    return service.get_progress(current_user.id)
