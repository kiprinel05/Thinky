import torch
import torchvision.transforms as transforms
from PIL import Image
from typing import Any, Union
import io

from ml.core.base_model import BaseMLModel
from ml.models.definitions import ShapeClassifier

class ShapeModel(BaseMLModel):
    def __init__(self, model_path: str):
        super().__init__(model_path)
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.classes = ["Circle", "Square", "Triangle"]
        
        self.transform = transforms.Compose([
            transforms.Resize((128, 128)),
            transforms.ToTensor(),
            # Normalization might be needed depending on training, using standard for now if unknown
            # transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5)) 
        ])

    def load(self) -> None:
        try:
            self.model = ShapeClassifier(num_classes=len(self.classes))
            state_dict = torch.load(self.model_path, map_location=self.device)
            self.model.load_state_dict(state_dict)
            self.model.to(self.device)
            self.model.eval()
            self._is_loaded = True
            print(f"ShapeModel loaded from {self.model_path}")
        except FileNotFoundError:
             print(f"[WARNING] ShapeModel file not found at {self.model_path}")
             self._is_loaded = False
        except Exception as e:
            print(f"[ERROR] Failed to load ShapeModel: {e}")
            self._is_loaded = False

    def predict(self, input_data: Union[bytes, Image.Image]) -> str:
        """
        Input: helper bytes or PIL Image
        Returns: Class label string
        """
        if not self._is_loaded:
            raise RuntimeError("Model not loaded")

        # Preprocessing
        if isinstance(input_data, bytes):
            image = Image.open(io.BytesIO(input_data)).convert("RGB")
        elif isinstance(input_data, Image.Image):
            image = input_data.convert("RGB")
        else:
            raise ValueError("Input must be bytes or PIL Image")

        input_tensor = self.transform(image).unsqueeze(0).to(self.device)

        with torch.no_grad():
            outputs = self.model(input_tensor)
            _, predicted = torch.max(outputs, 1)
            class_idx = predicted.item()

        return self.classes[class_idx]
