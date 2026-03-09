from core.base.repository import BaseRepository
from features.workshop.models import WorkshopMission
from features.workshop.schemas import WorkshopMissionCreate, WorkshopMissionUpdate


class WorkshopRepository(BaseRepository[WorkshopMission, WorkshopMissionCreate, WorkshopMissionUpdate]):
    pass
