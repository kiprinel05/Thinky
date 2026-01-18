from pydantic import BaseModel

class ShapePredictionResponse(BaseModel):
    predicted_shape: str
