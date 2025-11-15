from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class MissionBase(BaseModel):
    title: str
    mission_path: str
    description: Optional[str] = None
    order_index: int = 0
    background_color: Optional[str] = None
    height: Optional[float] = 200.0

class MissionCreate(MissionBase):
    pass

class MissionResponse(MissionBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class MissionProgressResponse(BaseModel):
    mission_id: int
    is_completed: bool
    completed_at: Optional[datetime] = None
    score: Optional[float] = None
    
    class Config:
        from_attributes = True

class MissionWithProgress(MissionResponse):
    progress: Optional[MissionProgressResponse] = None
    is_locked: bool = True

class MissionListResponse(BaseModel):
    missions: List[MissionWithProgress]

class MissionCompleteRequest(BaseModel):
    score: Optional[float] = None

