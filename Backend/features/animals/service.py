import random
from pathlib import Path
from typing import List, Dict

from .schemas import AnimalImage, GuessResponse, TeachingImagesResponse, ValidateTeachingResponse
from .model import AnimalClassifier, ALL_CATEGORIES


class AnimalMissionService:
    """Service for the Animals Mission — powered by a real MobileNetV2 classifier."""

    ANIMAL_TYPES = ALL_CATEGORIES

    ANIMALS_DATASET_PATH = Path(__file__).parent.parent.parent / "Resources" / "Animals Dataset"

    SKILL_INITIAL = 0.3
    SKILL_INCREMENT = 0.15
    SKILL_CAP = 0.95

    def __init__(self):
        self._image_cache: Dict[str, List[str]] = {}
        self._classifier = AnimalClassifier()
        self._classifier.load()
        self._load_image_cache()

    def _load_image_cache(self):
        for animal in self.ANIMAL_TYPES:
            animal_path = self.ANIMALS_DATASET_PATH / animal
            if animal_path.exists():
                images = [f.name for f in animal_path.iterdir()
                          if f.suffix.lower() in ['.jpg', '.jpeg', '.png']][:50]
                self._image_cache[animal] = images
            else:
                self._image_cache[animal] = []

    def get_random_image(self, exclude_ids: List[str] = None) -> AnimalImage:
        exclude_ids = exclude_ids or []

        animal = random.choice(self.ANIMAL_TYPES)

        available = [img for img in self._image_cache.get(animal, [])
                     if f"{animal}_{img}" not in exclude_ids]

        if not available:
            available = self._image_cache.get(animal, ["1.jpeg"])

        image_file = random.choice(available)
        image_id = f"{animal}_{image_file}"

        return AnimalImage(
            id=image_id,
            url=f"/animals/image/{animal}/{image_file}",
            label=animal
        )

    def make_guess(self, image_id: str, skill_level: float) -> GuessResponse:
        """
        Pixy guesses the animal using real MobileNetV2 inference,
        tempered by the current skill_level.
        """
        parts = image_id.split("_", 1)
        actual_animal = parts[0] if parts else "unknown"

        image_file = parts[1] if len(parts) > 1 else ""
        image_path = str(self.ANIMALS_DATASET_PATH / actual_animal / image_file)

        guess, confidence, _probs = self._classifier.predict_with_skill(
            image_path, skill_level
        )

        return GuessResponse(
            guess=guess,
            confidence=round(confidence, 2),
            actual_animal=actual_animal,
            is_correct=(guess == actual_animal)
        )

    def get_teaching_images(self, target_animal: str, count: int = 6) -> TeachingImagesResponse:
        images = []
        correct_ids = []

        target_count = count // 2 + 1
        target_images = self._image_cache.get(target_animal, [])[:20]
        selected_targets = random.sample(target_images, min(target_count, len(target_images)))

        for img_file in selected_targets:
            img_id = f"{target_animal}_{img_file}"
            images.append(AnimalImage(
                id=img_id,
                url=f"/animals/image/{target_animal}/{img_file}",
                label=target_animal
            ))
            correct_ids.append(img_id)

        other_animals = [a for a in self.ANIMAL_TYPES if a != target_animal]
        remaining_count = count - len(images)

        for _ in range(remaining_count):
            other_animal = random.choice(other_animals)
            other_images = self._image_cache.get(other_animal, [])[:20]
            if other_images:
                img_file = random.choice(other_images)
                images.append(AnimalImage(
                    id=f"{other_animal}_{img_file}",
                    url=f"/animals/image/{other_animal}/{img_file}",
                    label=other_animal
                ))

        random.shuffle(images)

        return TeachingImagesResponse(
            target_animal=target_animal,
            images=images,
            correct_image_ids=correct_ids
        )

    def validate_teaching(
        self,
        target_animal: str,
        selected_ids: List[str],
        correct_ids: List[str]
    ) -> ValidateTeachingResponse:
        selected_set = set(selected_ids)
        correct_set = set(correct_ids)

        correct_selections = selected_set & correct_set
        missed = correct_set - selected_set
        wrong = selected_set - correct_set

        is_correct = (missed == set() and wrong == set())

        if is_correct:
            message = f"Perfect! Pixy now knows what a {target_animal} looks like! 🎉"
        elif len(wrong) > 0 and len(missed) > 0:
            message = f"Almost! You selected some wrong images and missed some {target_animal}s."
        elif len(wrong) > 0:
            message = f"You selected {len(wrong)} image(s) that aren't {target_animal}s. Try again!"
        else:
            message = f"You missed {len(missed)} {target_animal}(s). Look more carefully!"

        return ValidateTeachingResponse(
            is_correct=is_correct,
            correct_count=len(correct_selections),
            total_correct=len(correct_set),
            missed_count=len(missed),
            wrong_count=len(wrong),
            message=message
        )

    def get_image_path(self, animal: str, filename: str) -> Path:
        return self.ANIMALS_DATASET_PATH / animal / filename


_service_instance = None


def get_animal_service() -> AnimalMissionService:
    global _service_instance
    if _service_instance is None:
        _service_instance = AnimalMissionService()
    return _service_instance
