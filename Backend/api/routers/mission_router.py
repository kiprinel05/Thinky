from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import List
import sys
from pathlib import Path
from datetime import datetime

sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from database import get_db
from models.mission_model import Mission, MissionProgress
from models.user_model import User
from api.schemas.mission_schemas import (
    MissionResponse,
    MissionWithProgress,
    MissionListResponse,
    MissionCompleteRequest,
    MissionProgressResponse
)
from api.dependencies import get_current_user

router = APIRouter(prefix="/missions", tags=["Missions"])

@router.get("", response_model=MissionListResponse)
async def get_missions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all missions with user progress"""
    missions = db.query(Mission).filter(Mission.is_active == True).order_by(Mission.order_index).all()
    
    mission_list = []
    completed_mission_ids = set()
    
    # Get all user progress
    user_progress = db.query(MissionProgress).filter(
        MissionProgress.user_id == current_user.id,
        MissionProgress.is_completed == True
    ).all()
    
    completed_mission_ids = {p.mission_id for p in user_progress}
    
    # Get progress for each mission
    progress_map = {}
    all_progress = db.query(MissionProgress).filter(
        MissionProgress.user_id == current_user.id
    ).all()
    
    for progress in all_progress:
        progress_map[progress.mission_id] = MissionProgressResponse(
            mission_id=progress.mission_id,
            is_completed=progress.is_completed,
            completed_at=progress.completed_at,
            score=progress.score
        )
    
    # Determine locked status
    for i, mission in enumerate(missions):
        is_locked = False
        if i > 0:
            # Check if previous mission is completed
            previous_mission = missions[i - 1]
            is_locked = previous_mission.id not in completed_mission_ids
        
        progress = progress_map.get(mission.id)
        
        mission_with_progress = MissionWithProgress(
            id=mission.id,
            title=mission.title,
            mission_path=mission.mission_path,
            description=mission.description,
            order_index=mission.order_index,
            background_color=mission.background_color,
            height=mission.height,
            is_active=mission.is_active,
            created_at=mission.created_at,
            progress=progress,
            is_locked=is_locked
        )
        mission_list.append(mission_with_progress)
    
    return MissionListResponse(missions=mission_list)

@router.post("/{mission_id}/complete", response_model=MissionProgressResponse)
async def complete_mission(
    mission_id: int,
    request: MissionCompleteRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a mission as completed"""
    mission = db.query(Mission).filter(Mission.id == mission_id).first()
    if not mission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mission not found"
        )
    
    # Check if mission is locked
    if mission.order_index > 0:
        previous_missions = db.query(Mission).filter(
            Mission.order_index < mission.order_index,
            Mission.is_active == True
        ).order_by(Mission.order_index.desc()).all()
        
        if previous_missions:
            previous_mission = previous_missions[0]
            previous_progress = db.query(MissionProgress).filter(
                and_(
                    MissionProgress.user_id == current_user.id,
                    MissionProgress.mission_id == previous_mission.id,
                    MissionProgress.is_completed == True
                )
            ).first()
            
            if not previous_progress:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Previous mission must be completed first"
                )
    
    # Check if already completed
    existing_progress = db.query(MissionProgress).filter(
        and_(
            MissionProgress.user_id == current_user.id,
            MissionProgress.mission_id == mission_id
        )
    ).first()
    
    if existing_progress:
        if existing_progress.is_completed:
            return MissionProgressResponse(
                mission_id=existing_progress.mission_id,
                is_completed=existing_progress.is_completed,
                completed_at=existing_progress.completed_at,
                score=existing_progress.score
            )
        # Update existing progress
        existing_progress.is_completed = True
        existing_progress.completed_at = datetime.utcnow()
        if request.score is not None:
            existing_progress.score = request.score
        db.commit()
        db.refresh(existing_progress)
        
        return MissionProgressResponse(
            mission_id=existing_progress.mission_id,
            is_completed=existing_progress.is_completed,
            completed_at=existing_progress.completed_at,
            score=existing_progress.score
        )
    
    # Create new progress
    new_progress = MissionProgress(
        user_id=current_user.id,
        mission_id=mission_id,
        is_completed=True,
        completed_at=datetime.utcnow(),
        score=request.score
    )
    
    db.add(new_progress)
    db.commit()
    db.refresh(new_progress)
    
    return MissionProgressResponse(
        mission_id=new_progress.mission_id,
        is_completed=new_progress.is_completed,
        completed_at=new_progress.completed_at,
        score=new_progress.score
    )

@router.get("/progress", response_model=List[MissionProgressResponse])
async def get_user_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all mission progress for current user"""
    progress_list = db.query(MissionProgress).filter(
        MissionProgress.user_id == current_user.id
    ).all()
    
    return [
        MissionProgressResponse(
            mission_id=p.mission_id,
            is_completed=p.is_completed,
            completed_at=p.completed_at,
            score=p.score
        )
        for p in progress_list
    ]

