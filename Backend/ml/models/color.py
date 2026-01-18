import torch
import numpy as np
from typing import Any, List
from ml.core.base_model import BaseMLModel
from ml.models.definitions import ColorClassifier

class ColorModel(BaseMLModel):
    def __init__(self, model_path: str):
        super().__init__(model_path)
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.classes = ["red", "green", "blue", "yellow", "orange", "purple", "pink", "brown", "black", "white"]

    def load(self) -> None:
        try:
            self.model = ColorClassifier(num_classes=len(self.classes))
            # Load weights
            state_dict = torch.load(self.model_path, map_location=self.device)
            self.model.load_state_dict(state_dict)
            self.model.to(self.device)
            self.model.eval()
            self._is_loaded = True
            print(f"ColorModel loaded from {self.model_path}")
        except FileNotFoundError:
            print(f"[WARNING] ColorModel model file not found at {self.model_path}")
            # Ensure we can still instantiate for testing but _is_loaded stays False OR we provide a mock behavior if critical
            self._is_loaded = False
        except Exception as e:
            print(f"[ERROR] Failed to load ColorModel: {e}")
            self._is_loaded = False

    def predict(self, input_data: Any) -> str:
        """
        Input: RGB tuple or list [r, g, b] scaled 0-255 or 0-1
        Returns: Class label string
        """
        if not self._is_loaded:
             raise RuntimeError("Model not loaded")

        # Preprocessing
        if isinstance(input_data, list) or isinstance(input_data, tuple):
             # Assume safe input for now, but should validate
             input_tensor = torch.tensor([input_data], dtype=torch.float32).to(self.device)
        else:
             raise ValueError("Input must be a list or tuple of 3 values (RGB)")

        with torch.no_grad():
            outputs = self.model(input_tensor)
            _, predicted = torch.max(outputs, 1)
            class_idx = predicted.item()
            
        return self.classes[class_idx]
