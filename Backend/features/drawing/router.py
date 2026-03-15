from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from features.drawing.schemas import DrawingAnalysisResponse
from features.drawing.service import drawing_service

router = APIRouter(prefix="/drawing", tags=["Drawing Analysis"])


@router.post("/analyze", response_model=DrawingAnalysisResponse)
async def analyze_drawing(
    file: UploadFile = File(..., description="PNG or JPG image of the drawing"),
    target_shape: str = Query("triangle", description="Expected shape to detect"),
    target_color: str = Query("blue", description="Expected color to detect"),
    require_fill: bool = Query(False, description="If False, outline shapes are accepted (no min coverage)"),
):
    """
    Analyze a user's drawing for shape and color detection.
    
    Used for creative missions like "Draw a blue triangle".
    
    Returns:
        - Detected shape and color
        - Whether it matches the target
        - Confidence scores
        - User feedback message
        - Pixy mascot emotion state
    """
    try:
        # Validate file type
        if file.content_type not in ["image/png", "image/jpeg", "image/jpg"]:
            raise HTTPException(
                status_code=400, 
                detail="Only PNG and JPG images are supported"
            )
        
        contents = await file.read()
        
        # Validate file size (max 5MB)
        if len(contents) > 5 * 1024 * 1024:
            raise HTTPException(
                status_code=400,
                detail="Image too large. Maximum size is 5MB."
            )
        
        result = drawing_service.analyze_drawing(
            contents,
            target_shape=target_shape,
            target_color=target_color,
            require_fill=require_fill,
        )
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Drawing analysis endpoint failed: {e}")
        raise HTTPException(
            status_code=500, 
            detail=f"Error analyzing drawing: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check for drawing service."""
    return {"status": "ok", "service": "drawing"}
