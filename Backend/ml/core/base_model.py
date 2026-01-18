from abc import ABC, abstractmethod
from typing import Any, Optional

class BaseMLModel(ABC):
    """
    Abstract base class for all Machine Learning models.
    Enforces a standard interface for loading artifacts and making predictions.
    """
    
    def __init__(self, model_path: str):
        self.model_path = model_path
        self.model = None
        self._is_loaded = False

    @abstractmethod
    def load(self) -> None:
        """
        Load the model artifacts (weights, config) from disk.
        Should set self.model and self._is_loaded = True
        """
        pass

    @abstractmethod
    def predict(self, input_data: Any) -> Any:
        """
        Make a prediction based on input data.
        Should raise ValueError if model is not loaded.
        """
        pass
    
    @property
    def is_loaded(self) -> bool:
        return self._is_loaded
