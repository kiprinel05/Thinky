from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime, timezone

from core.base.repository import BaseRepository
from features.mission.models import Mission, MissionProgress
from features.mission.schemas import MissionCreate, MissionResponse

class MissionRepository(BaseRepository[Mission, MissionCreate, MissionCreate]):
    def get_active_missions_ordered(self) -> List[Mission]:
        return self.db.query(Mission).filter(Mission.is_active == True).order_by(Mission.order_index).all()
        
    def get_user_progress(self, user_id: int) -> List[MissionProgress]:
        return self.db.query(MissionProgress).filter(
            MissionProgress.user_id == user_id
        ).all()
        
    def get_completed_progress(self, user_id: int) -> List[MissionProgress]:
        return self.db.query(MissionProgress).filter(
            MissionProgress.user_id == user_id,
            MissionProgress.is_completed == True
        ).all()
        
    def get_progress_by_mission(self, user_id: int, mission_id: int) -> Optional[MissionProgress]:
        return self.db.query(MissionProgress).filter(
            and_(
                MissionProgress.user_id == user_id,
                MissionProgress.mission_id == mission_id
            )
        ).first()

    def get_previous_missions(self, order_index: int) -> List[Mission]:
         return self.db.query(Mission).filter(
            Mission.order_index < order_index,
            Mission.is_active == True
        ).order_by(Mission.order_index.desc()).all()
