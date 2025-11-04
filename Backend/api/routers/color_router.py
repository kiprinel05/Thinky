from fastapi import APIRouter, HTTPException
import torch
import sys
from pathlib import Path

# Adaugă parent directory la path pentru import
sys.path.append(str(Path(__file__).resolve().parent.parent))
from api.utils import get_model, get_labels

router = APIRouter(prefix="/color", tags=["Color Classification"])

@router.post("/predict")
async def predict_color(r: int, g: int, b: int):
    model = get_model("color")
    labels = get_labels("color")

    if model is None:
        raise HTTPException(status_code=503, detail="Color model not loaded")

    try:
        rgb = torch.tensor([[r, g, b]], dtype=torch.float32) / 255.0
        with torch.no_grad():
            outputs = model(rgb)
            _, pred = torch.max(outputs, 1)
        return {"predicted_color": labels[pred.item()]}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing input: {e}")
