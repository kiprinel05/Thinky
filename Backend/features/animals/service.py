import os
import random
from pathlib import Path
from typing import List, Tuple, Dict
from .schemas import AnimalImage, GuessResponse, TeachingImagesResponse, ValidateTeachingResponse


class AnimalMissionService:
    """Service for the Animals Mission - teaches Pixy to recognize animals."""
    
    # Available animal categories
    ANIMAL_TYPES = ["cat", "dog", "elephant", "horse", "chicken"]
    
    # Base path to animal images
    ANIMALS_DATASET_PATH = Path(__file__).parent.parent.parent / "Resources" / "Animals Dataset"
    
    # Intentionally wrong guesses for teaching moments (maps actual -> wrong guess)
    # This simulates a weak model that hasn't learned well
    CONFUSION_MATRIX = {
        "cat": ["dog", "chicken"],
        "dog": ["cat", "horse"],
        "elephant": ["horse", "dog"],
        "horse": ["dog", "elephant"],
        "chicken": ["cat", "dog"],
    }
    
    # Probability that Pixy guesses wrong (for teaching moments)
    ERROR_RATE = 0.6  # 60% chance of wrong guess
    
    def __init__(self):
        self._image_cache: Dict[str, List[str]] = {}
        self._load_image_cache()
    
    def _load_image_cache(self):
        """Load available images for each animal type."""
        for animal in self.ANIMAL_TYPES:
            animal_path = self.ANIMALS_DATASET_PATH / animal
            if animal_path.exists():
                # Get first 50 images for each animal (to keep it manageable)
                images = [f.name for f in animal_path.iterdir() 
                         if f.suffix.lower() in ['.jpg', '.jpeg', '.png']][:50]
                self._image_cache[animal] = images
            else:
                self._image_cache[animal] = []
    
    def get_random_image(self, exclude_ids: List[str] = None) -> AnimalImage:
        """Get a random animal image."""
        exclude_ids = exclude_ids or []
        
        # Pick random animal type
        animal = random.choice(self.ANIMAL_TYPES)
        
        # Get available images
        available = [img for img in self._image_cache.get(animal, [])
                    if f"{animal}_{img}" not in exclude_ids]
        
        if not available:
            # Fallback if no images available
            available = self._image_cache.get(animal, ["1.jpeg"])
        
        image_file = random.choice(available)
        image_id = f"{animal}_{image_file}"
        
        return AnimalImage(
            id=image_id,
            url=f"/animals/image/{animal}/{image_file}",
            label=animal
        )
    
    def make_guess(self, image_id: str) -> GuessResponse:
        """
        Pixy makes a guess about what animal is in the image.
        Intentionally gets it wrong sometimes for teaching moments.
        """
        # Parse the actual animal from image_id (format: "animal_filename")
        parts = image_id.split("_", 1)
        actual_animal = parts[0] if parts else "unknown"
        
        # Decide if Pixy should guess wrong (for teaching)
        should_be_wrong = random.random() < self.ERROR_RATE
        
        if should_be_wrong and actual_animal in self.CONFUSION_MATRIX:
            # Pick a wrong guess from confusion options
            guess = random.choice(self.CONFUSION_MATRIX[actual_animal])
            confidence = random.uniform(0.3, 0.6)  # Lower confidence when wrong
        else:
            # Correct guess
            guess = actual_animal
            confidence = random.uniform(0.7, 0.95)  # Higher confidence when right
        
        return GuessResponse(
            guess=guess,
            confidence=round(confidence, 2),
            actual_animal=actual_animal,
            is_correct=(guess == actual_animal)
        )
    
    def get_teaching_images(self, target_animal: str, count: int = 6) -> TeachingImagesResponse:
        """
        Get a grid of images for the teaching phase.
        Mix of target animal and other animals.
        """
        images = []
        correct_ids = []
        
        # Add target animal images (about half)
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
        
        # Add other animal images
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
        
        # Shuffle the images
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
        """Validate user's teaching selections."""
        selected_set = set(selected_ids)
        correct_set = set(correct_ids)
        
        # Calculate metrics
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
        """Get the file path for an animal image."""
        return self.ANIMALS_DATASET_PATH / animal / filename


# Singleton instance
_service_instance = None

def get_animal_service() -> AnimalMissionService:
    """Get or create the animal service singleton."""
    global _service_instance
    if _service_instance is None:
        _service_instance = AnimalMissionService()
    return _service_instance
