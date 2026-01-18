from pydantic import BaseModel

class ColorPredictionRequest(BaseModel):
    r: int
    g: int
    b: int

class ColorPredictionResponse(BaseModel):
    predicted_color: str
