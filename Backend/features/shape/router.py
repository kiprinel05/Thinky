from fastapi import APIRouter, UploadFile, File, HTTPException
from features.shape.schemas import ShapePredictionResponse
from features.shape.service import shape_service

router = APIRouter(prefix="/shape", tags=["Shape Classification"])

@router.post("/predict", response_model=ShapePredictionResponse)
async def predict_shape(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        prediction = shape_service.predict(contents)
        return ShapePredictionResponse(predicted_shape=prediction)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing image: {str(e)}")
