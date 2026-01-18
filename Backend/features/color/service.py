from core.config import settings
from ml.models.color import ColorModel
from features.color.schemas import ColorPredictionRequest

class ColorService:
    def __init__(self):
        self.model = ColorModel(settings.MODEL_PATH_COLOR)
        self.model.load()

    def predict(self, r: int, g: int, b: int) -> str:
        # Preprocessing: ML model expects [R, G, B] normalized? 
        # Looking at legacy router: rgb = torch.tensor([[r, g, b]], dtype=torch.float32) / 255.0
        # My BaseMLModel wrapper just took the input. I should probably ensure the wrapper handles normalization or do it here.
        # But looking at my wrapper: input_tensor = torch.tensor([input_data]). 
        # I should have added normalization in the wrapper if it wasn't there. 
        # Actually my wrapper implementation for ColorModel just took the list.
        # Let's normalize here to match legacy behavior which divided by 255.0.
        
        normalized_input = [r / 255.0, g / 255.0, b / 255.0]
        return self.model.predict(normalized_input)

# Singleton to keep model loaded in memory
color_service = ColorService()
