from typing import List, Optional, Tuple
from datetime import datetime, timezone

from core.base.service import BaseService
from features.mission.models import Mission, MissionProgress
from features.mission.schemas import (
    MissionCreate, MissionResponse, MissionListResponse, 
    MissionWithProgress, MissionProgressResponse
)
from features.mission.repository import MissionRepository

class MissionService(BaseService[Mission, MissionCreate, MissionCreate]):
    def __init__(self, repository: MissionRepository):
        super().__init__(repository)
        self.repository = repository

    def get_missions_for_user(self, user_id: Optional[int]) -> MissionListResponse:
        missions = self.repository.get_active_missions_ordered()
        
        mission_list = []
        completed_mission_ids = set()
        progress_map = {}
        
        if user_id:
            user_progress = self.repository.get_completed_progress(user_id)
            completed_mission_ids = {p.mission_id for p in user_progress}
            
            all_progress = self.repository.get_user_progress(user_id)
            for progress in all_progress:
                progress_map[progress.mission_id] = MissionProgressResponse(
                    mission_id=progress.mission_id,
                    is_completed=progress.is_completed,
                    completed_at=progress.completed_at,
                    score=progress.score
                )
        
        for i, mission in enumerate(missions):
            is_locked = False
            if user_id:
                if i > 0:
                    previous_mission = missions[i - 1]
                    is_locked = previous_mission.id not in completed_mission_ids
            else:
                is_locked = i > 0
            
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

    def complete_mission(self, user_id: int, mission_id: int, score: Optional[float] = None) -> MissionProgressResponse:
        mission = self.repository.get(mission_id)
        if not mission:
            raise ValueError("Mission not found")
            
        # Check locking logic
        if mission.order_index > 0:
            previous_missions = self.repository.get_previous_missions(mission.order_index)
            if previous_missions:
                previous_mission = previous_missions[0]
                previous_progress = self.repository.get_progress_by_mission(user_id, previous_mission.id)
                
                if not previous_progress or not previous_progress.is_completed:
                    raise PermissionError("Previous mission must be completed first")
        
        existing_progress = self.repository.get_progress_by_mission(user_id, mission_id)
        
        if existing_progress:
            if not existing_progress.is_completed:
                existing_progress.is_completed = True
                existing_progress.completed_at = datetime.now(timezone.utc)
                if score is not None:
                    existing_progress.score = score
                self.repository.db.commit()
                self.repository.db.refresh(existing_progress)
            
            # If already completed, we might just return it (or update score if higher? logic says existing implementation just returned)
            return MissionProgressResponse(
                mission_id=existing_progress.mission_id,
                is_completed=existing_progress.is_completed,
                completed_at=existing_progress.completed_at,
                score=existing_progress.score
            )
            
        new_progress = MissionProgress(
            user_id=user_id,
            mission_id=mission_id,
            is_completed=True,
            completed_at=datetime.now(timezone.utc),
            score=score
        )
        self.repository.db.add(new_progress)
        self.repository.db.commit()
        self.repository.db.refresh(new_progress)
        
        return MissionProgressResponse(
            mission_id=new_progress.mission_id,
            is_completed=new_progress.is_completed,
            completed_at=new_progress.completed_at,
            score=new_progress.score
        )

    def get_user_progress_list(self, user_id: int) -> List[MissionProgressResponse]:
        progress_list = self.repository.get_user_progress(user_id)
        return [
            MissionProgressResponse(
                mission_id=p.mission_id,
                is_completed=p.is_completed,
                completed_at=p.completed_at,
                score=p.score
            )
            for p in progress_list
        ]
