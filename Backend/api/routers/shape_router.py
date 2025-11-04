from fastapi import APIRouter, File, UploadFile, HTTPException
from torchvision import transforms
from PIL import Image
import torch
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from api.utils import get_model
from config import CLASSES

router = APIRouter(prefix="/shape", tags=["Shape Classification"])

transform = transforms.Compose([
    transforms.Resize((128, 128)),
    transforms.ToTensor(),
])

@router.post("/predict")
async def predict_shape(file: UploadFile = File(...)):
    model = get_model("shape")
    if model is None:
        raise HTTPException(status_code=503, detail="Shape model not loaded")

    try:
        image = Image.open(file.file).convert("RGB")
        x = transform(image).unsqueeze(0)
        with torch.no_grad():
            outputs = model(x)
            _, pred = torch.max(outputs, 1)
        return {"predicted_shape": CLASSES["shape"][pred.item()]}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing image: {e}")
