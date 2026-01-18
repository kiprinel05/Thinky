from core.config import settings
from ml.models.shape import ShapeModel
from PIL import Image
import io

class ShapeService:
    def __init__(self):
        self.model = ShapeModel(settings.MODEL_PATH_SHAPE)
        self.model.load()

    def predict(self, image_bytes: bytes) -> str:
        return self.model.predict(image_bytes)

shape_service = ShapeService()
