from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional

# Support both old (api/) and new (features/) architecture
try:
    from api.dependencies import get_current_user
    from database import get_db
    from models.user_model import User
except ImportError:
    from core.database import get_db
    from features.auth.dependencies import get_current_user
    from features.auth.models import User
from features.workshop.service import WorkshopService
from features.workshop.schemas import (
    WorkshopMissionCreate,
    WorkshopMissionUpdate,
    WorkshopMissionResponse,
    WorkshopMissionDetailResponse,
    WorkshopMissionListResponse,
)

router = APIRouter(prefix="/workshop", tags=["Workshop"])


def get_workshop_service(db: Session = Depends(get_db)) -> WorkshopService:
    return WorkshopService(db)


# ══════════════════════════════════════════════════════════════════════════════
# BROWSE
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/missions", response_model=WorkshopMissionListResponse)
async def get_missions(
    search: Optional[str] = Query(None, description="Search by title or description"),
    tags: Optional[str] = Query(None, description="Comma-separated tags to filter"),
    sort_by: str = Query("recent", description="Sort by: recent, popular"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    service: WorkshopService = Depends(get_workshop_service),
):
    """Browse workshop missions with search, tag filtering, and sorting."""
    tag_list = [t.strip() for t in tags.split(",")] if tags else None
    return service.get_missions(
        search=search,
        tags=tag_list,
        sort_by=sort_by,
        page=page,
        limit=limit,
    )


# ══════════════════════════════════════════════════════════════════════════════
# DETAIL
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/missions/{mission_id}", response_model=WorkshopMissionDetailResponse)
async def get_mission_detail(
    mission_id: int,
    service: WorkshopService = Depends(get_workshop_service),
):
    """Get full mission detail including quiz questions."""
    detail = service.get_mission_detail(mission_id)
    if not detail:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mission not found",
        )
    return detail


# ══════════════════════════════════════════════════════════════════════════════
# UPLOAD
# ══════════════════════════════════════════════════════════════════════════════

@router.post("/upload", response_model=WorkshopMissionResponse, status_code=status.HTTP_201_CREATED)
async def upload_mission(
    data: WorkshopMissionCreate,
    current_user: User = Depends(get_current_user),
    service: WorkshopService = Depends(get_workshop_service),
):
    """Upload a new mission to the workshop."""
    try:
        return service.create_mission(current_user.id, data)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


# ══════════════════════════════════════════════════════════════════════════════
# DOWNLOAD
# ══════════════════════════════════════════════════════════════════════════════

@router.post("/download/{mission_id}", response_model=WorkshopMissionDetailResponse)
async def download_mission(
    mission_id: int,
    current_user: User = Depends(get_current_user),
    service: WorkshopService = Depends(get_workshop_service),
):
    """Download a mission (increments download count, returns full quiz data)."""
    result = service.download_mission(current_user.id, mission_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mission not found",
        )
    return result


# ══════════════════════════════════════════════════════════════════════════════
# MY MISSIONS
# ══════════════════════════════════════════════════════════════════════════════

@router.get("/my-missions", response_model=WorkshopMissionListResponse)
async def get_my_missions(
    current_user: User = Depends(get_current_user),
    service: WorkshopService = Depends(get_workshop_service),
):
    """Get all missions created by the current user."""
    return service.get_my_missions(current_user.id)


# ══════════════════════════════════════════════════════════════════════════════
# UPDATE
# ══════════════════════════════════════════════════════════════════════════════

@router.put("/missions/{mission_id}", response_model=WorkshopMissionResponse)
async def update_mission(
    mission_id: int,
    data: WorkshopMissionUpdate,
    current_user: User = Depends(get_current_user),
    service: WorkshopService = Depends(get_workshop_service),
):
    """Update an existing mission (author only). Bumps version if questions change."""
    try:
        result = service.update_mission(current_user.id, mission_id, data)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mission not found or you are not the author",
        )
    return result
