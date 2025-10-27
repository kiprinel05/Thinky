import torch
from config import MODEL_PATHS
from models.shape_model.model import ShapeClassifier
from models.color_model.model import ColorClassifier

_loaded_models = {}
_label_maps = {}

def load_model(model_name: str):
    if model_name == "shape":
        model = ShapeClassifier(num_classes=3)
    elif model_name == "color":
        checkpoint = torch.load(MODEL_PATHS["color"], map_location="cpu")
        model = ColorClassifier(num_classes=len(checkpoint["labels"]))
        model.load_state_dict(checkpoint["state_dict"])
        _label_maps["color"] = checkpoint["labels"]
        model.eval()
        return model
    else:
        raise ValueError("Unknown model name.")

    model.load_state_dict(torch.load(MODEL_PATHS[model_name], map_location="cpu"))
    model.eval()
    return model

def init_models():
    global _loaded_models
    for name in MODEL_PATHS:
        try:
            _loaded_models[name] = load_model(name)
            print(f"✅ Loaded model: {name}")
        except Exception as e:
            print(f"⚠️ Could not load model '{name}': {e}")

def get_model(name: str):
    return _loaded_models.get(name)

def get_labels(name: str):
    return _label_maps.get(name)
