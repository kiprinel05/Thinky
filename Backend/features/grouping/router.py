from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse
from .schemas import (
    GroupingStartResponse,
    GroupingRoundResponse,
    GroupingSubmitRequest,
    GroupingSubmitResponse,
)
from .service import get_grouping_service

router = APIRouter(prefix="/grouping", tags=["Grouping Mission"])


@router.get("/start")
async def start_mission() -> GroupingStartResponse:
    """Start a new grouping mission."""
    service = get_grouping_service()
    return service.start_mission()


@router.get("/round")
async def get_round() -> GroupingRoundResponse:
    """Get items to sort for the current round."""
    service = get_grouping_service()
    
    try:
        return service.get_round()
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/submit")
async def submit_grouping(request: GroupingSubmitRequest) -> GroupingSubmitResponse:
    """
    Submit user's grouping assignments for validation.
    
    Expects:
    - assignments: Dict mapping item_id to user's chosen category
    - time_spent: Seconds taken by the user
    """
    service = get_grouping_service()
    
    try:
        return service.validate_grouping(
            assignments=request.assignments,
            time_spent=request.time_spent,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/summary")
async def get_summary():
    """Get overall mission performance summary."""
    service = get_grouping_service()
    summary = service.get_mission_summary()
    is_complete = service.is_mission_complete()
    
    return {
        "is_complete": is_complete,
        **summary,
    }


@router.get("/image/{category}/{filename}")
async def get_image(category: str, filename: str):
    """Serve a grouping item image."""
    service = get_grouping_service()
    image_path = service.get_image_path(category, filename)
    
    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")
    
    return FileResponse(image_path, media_type="image/png")
