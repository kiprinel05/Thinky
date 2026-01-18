from fastapi import APIRouter, HTTPException, Depends
from features.color.schemas import ColorPredictionRequest, ColorPredictionResponse
from features.color.service import color_service, ColorService

router = APIRouter(prefix="/color", tags=["Color Classification"])

@router.post("/predict", response_model=ColorPredictionResponse)
async def predict_color(request: ColorPredictionRequest):
    try:
        prediction = color_service.predict(request.r, request.g, request.b)
        return ColorPredictionResponse(predicted_color=prediction)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing input: {str(e)}")
