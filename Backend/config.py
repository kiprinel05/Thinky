from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

MODEL_PATHS = {
    "shape": BASE_DIR / "models" / "shape_model" / "saved_model.pth",
    "color": BASE_DIR / "models" / "color_model" / "saved_model.pth",
}

CLASSES = {
    "shape": ["Circle", "Square", "Triangle"],
    "color": ["red", "green", "blue", "yellow", "orange", "purple", "pink", "brown", "black", "white"]
}
