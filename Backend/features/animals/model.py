import random
from pathlib import Path
from typing import Dict, Tuple

import torch
import torch.nn.functional as F
from torchvision import models, transforms
from PIL import Image

from ml.core.base_model import BaseMLModel

# ImageNet class indices grouped by our 5 animal categories.
# Source: https://gist.github.com/yrevar/942d3a0ac09ec9e5eb3a (ImageNet 1000 class idx)
IMAGENET_TO_ANIMAL: Dict[str, list] = {
    "cat": list(range(281, 286)),          # tabby, tiger_cat, Persian, Siamese, Egyptian
    "dog": list(range(151, 269)),          # 118 dog breeds
    "elephant": [385, 386],                # Indian elephant, African elephant
    "horse": [339, 603],                   # sorrel, horse-related
    "chicken": [7, 8, 136, 137],           # cock, hen, Old English, wire-haired
}

# Reverse lookup: ImageNet index -> our category
_IDX_TO_CATEGORY: Dict[int, str] = {}
for _cat, _indices in IMAGENET_TO_ANIMAL.items():
    for _idx in _indices:
        _IDX_TO_CATEGORY[_idx] = _cat

ALL_CATEGORIES = list(IMAGENET_TO_ANIMAL.keys())

# Plausible confusions between visually similar animals
CONFUSION_MATRIX: Dict[str, list] = {
    "cat": ["dog", "chicken"],
    "dog": ["cat", "horse"],
    "elephant": ["horse", "dog"],
    "horse": ["dog", "elephant"],
    "chicken": ["cat", "dog"],
}

# Standard ImageNet preprocessing
_TRANSFORM = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225]),
])


class AnimalClassifier(BaseMLModel):
    """
    Real CNN classifier for animal images using MobileNetV2 pre-trained on ImageNet.
    Aggregates the 1000-class output into 5 animal categories.
    """

    def __init__(self):
        super().__init__(model_path="mobilenet_v2_pretrained")
        self._all_imagenet_indices = set(_IDX_TO_CATEGORY.keys())

    def load(self) -> None:
        try:
            self.model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.DEFAULT)
            self.model.eval()
            self._is_loaded = True
            print("[OK] AnimalClassifier (MobileNetV2) loaded successfully")
        except Exception as e:
            print(f"[ERROR] Failed to load AnimalClassifier: {e}")
            self._is_loaded = False

    def predict(self, input_data) -> Dict[str, float]:
        """
        Run inference on an image path and return category probabilities.
        Returns dict like {"cat": 0.72, "dog": 0.15, "elephant": 0.05, ...}
        """
        if not self._is_loaded:
            raise RuntimeError("AnimalClassifier model not loaded")

        image_path = Path(input_data)
        img = Image.open(image_path).convert("RGB")
        tensor = _TRANSFORM(img).unsqueeze(0)

        with torch.no_grad():
            logits = self.model(tensor)[0]  # shape: (1000,)

        # Max-pool logits per category to avoid bias towards categories with more ImageNet classes
        cat_logits = torch.zeros(len(ALL_CATEGORIES))
        for i, cat in enumerate(ALL_CATEGORIES):
            indices = IMAGENET_TO_ANIMAL[cat]
            cat_logits[i] = max(logits[idx].item() for idx in indices)

        probs = F.softmax(cat_logits, dim=0)
        category_scores = {ALL_CATEGORIES[i]: probs[i].item() for i in range(len(ALL_CATEGORIES))}
        return category_scores

    def predict_with_skill(
        self, image_path: str, skill_level: float
    ) -> Tuple[str, float, Dict[str, float]]:
        """
        Predict with a simulated skill level (0.0 = random, 1.0 = full accuracy).
        Returns (predicted_category, confidence, all_probabilities).

        At low skill: high temperature on logits blurs predictions, and there's
        a chance of swapping to a confused (wrong) answer.
        At high skill: near-raw model output.
        """
        if not self._is_loaded:
            # Graceful fallback to rule-based if model failed to load
            return self._fallback_predict(image_path, skill_level)

        skill = max(0.0, min(1.0, skill_level))

        image_path_obj = Path(image_path)
        img = Image.open(image_path_obj).convert("RGB")
        tensor = _TRANSFORM(img).unsqueeze(0)

        with torch.no_grad():
            logits = self.model(tensor)[0]

        # Max-pool logits per category (avoids bias toward categories with more ImageNet classes)
        cat_logits = torch.zeros(len(ALL_CATEGORIES))
        for i, cat in enumerate(ALL_CATEGORIES):
            indices = IMAGENET_TO_ANIMAL[cat]
            cat_logits[i] = max(logits[idx].item() for idx in indices)

        # Temperature scaling: low skill = high temperature = flatter distribution
        temperature = 0.5 + (1.0 - skill) * 4.0  # skill=0.3→T=3.3, skill=0.95→T=0.7
        scaled_logits = cat_logits / temperature
        probs = F.softmax(scaled_logits, dim=0)

        prob_dict = {ALL_CATEGORIES[i]: probs[i].item() for i in range(len(ALL_CATEGORIES))}

        best_cat = ALL_CATEGORIES[probs.argmax().item()]
        best_conf = prob_dict[best_cat]

        # At low skill, randomly swap to a confused category
        confusion_chance = max(0.0, (0.7 - skill) * 0.85)  # skill=0.3→38%, skill=0.7→0%
        if random.random() < confusion_chance and best_cat in CONFUSION_MATRIX:
            confused_cat = random.choice(CONFUSION_MATRIX[best_cat])
            best_conf = prob_dict.get(confused_cat, random.uniform(0.25, 0.5))
            best_cat = confused_cat

        return best_cat, round(best_conf, 3), prob_dict

    @staticmethod
    def _fallback_predict(
        image_path: str, skill_level: float
    ) -> Tuple[str, float, Dict[str, float]]:
        """Rule-based fallback when model is unavailable."""
        parts = Path(image_path).parent.name  # folder name = animal type
        actual = parts if parts in ALL_CATEGORIES else random.choice(ALL_CATEGORIES)

        should_be_wrong = random.random() > skill_level
        if should_be_wrong and actual in CONFUSION_MATRIX:
            guess = random.choice(CONFUSION_MATRIX[actual])
            conf = random.uniform(0.2, 0.5)
        else:
            guess = actual
            conf = random.uniform(0.6, 0.9)

        prob_dict = {c: 0.05 for c in ALL_CATEGORIES}
        prob_dict[guess] = conf
        return guess, round(conf, 3), prob_dict
