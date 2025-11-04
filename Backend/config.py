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

# JWT Settings
SECRET_KEY = "thinky-secret-key-change-in-production-environment"  # TODO: Change in production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days