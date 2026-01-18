from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from core.database import get_db
from features.auth.dependencies import get_current_user, get_current_user_optional
from features.auth.models import User
from features.mission.schemas import MissionListResponse, MissionProgressResponse, MissionCompleteRequest
from features.mission.service import MissionService
from features.mission.repository import MissionRepository
from features.mission.models import Mission

router = APIRouter(prefix="/missions", tags=["Missions"])

def get_mission_service(db: Session = Depends(get_db)) -> MissionService:
    repository = MissionRepository(Mission, db)
    return MissionService(repository)

@router.get("", response_model=MissionListResponse)
async def get_missions(
    current_user: Optional[User] = Depends(get_current_user_optional),
    service: MissionService = Depends(get_mission_service)
):
    user_id = current_user.id if current_user else None
    return service.get_missions_for_user(user_id)

@router.post("/{mission_id}/complete", response_model=MissionProgressResponse)
async def complete_mission(
    mission_id: int,
    request: MissionCompleteRequest,
    current_user: User = Depends(get_current_user),
    service: MissionService = Depends(get_mission_service)
):
    try:
        return service.complete_mission(current_user.id, mission_id, request.score)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except PermissionError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))

@router.get("/progress", response_model=List[MissionProgressResponse])
async def get_user_progress(
    current_user: User = Depends(get_current_user),
    service: MissionService = Depends(get_mission_service)
):
    return service.get_user_progress_list(current_user.id)
