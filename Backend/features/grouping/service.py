import random
from pathlib import Path
from typing import List, Dict, Tuple
from .schemas import (
    GroupingItem, 
    GroupingRoundResponse,
    GroupingSubmitResponse,
    GroupingItemResult,
    GroupingStartResponse
)


class GroupingMissionService:
    """
    Service for the Grouping Mission - sort images into categories.
    Categories: Fruits, Vegetables, Toys.
    Supports adaptive difficulty hooks.
    """
    
    CATEGORIES = ["fruits", "vegetables", "toys"]
    
    # Item definitions per category: (filename, display_name)
    ITEMS = {
        "fruits": [
            ("apple.png", "Apple"),
            ("banana.png", "Banana"),
            ("grape.png", "Grape"),
            ("orange.png", "Orange"),
            ("strawberry.png", "Strawberry"),
        ],
        "vegetables": [
            ("carrot.png", "Carrot"),
            ("broccoli.png", "Broccoli"),
            ("tomato.png", "Tomato"),
            ("pepper.png", "Pepper"),
            ("potato.png", "Potato"),
        ],
        "toys": [
            ("ball.png", "Ball"),
            ("car.png", "Toy Car"),
            ("doll.png", "Doll"),
            ("blocks.png", "Blocks"),
            ("teddy.png", "Teddy Bear"),
        ],
    }
    
    # Base path to grouping images
    DATASET_PATH = Path(__file__).parent.parent.parent / "Resources" / "Grouping Dataset"
    
    def __init__(self):
        self._session = {
            "current_round": 0,
            "total_rounds": 3,
            "rounds_completed": 0,
            "total_accuracy": 0.0,
            "total_time": 0.0,
            "current_items": [],  # Items for current round
        }
    
    def start_mission(self) -> GroupingStartResponse:
        """Start a new grouping mission, reset session."""
        self._session.update({
            "current_round": 0,
            "total_rounds": 3,
            "rounds_completed": 0,
            "total_accuracy": 0.0,
            "total_time": 0.0,
            "current_items": [],
        })
        return GroupingStartResponse(
            current_round=1,
            total_rounds=3,
            categories=self.CATEGORIES,
            message="Sort the images into the correct categories! 🎯"
        )
    
    def get_round(self, items_per_category: int = 0) -> GroupingRoundResponse:
        """
        Get items for the current round.
        Picks random items from each category.
        """
        if self._session["current_round"] >= self._session["total_rounds"]:
            raise ValueError("Mission already complete")
        
        self._session["current_round"] += 1
        
        # Adaptive difficulty: adjust items per category
        difficulty = self._get_difficulty_level()
        if items_per_category <= 0:
            items_per_category = min(2 + difficulty, 4)  # 2-4 items per category
        
        items = []
        for category in self.CATEGORIES:
            available = self.ITEMS.get(category, [])
            selected = random.sample(available, min(items_per_category, len(available)))
            
            for filename, display_name in selected:
                item_id = f"{category}_{filename.replace('.png', '')}"
                items.append(GroupingItem(
                    id=item_id,
                    url=f"/grouping/image/{category}/{filename}",
                    label=category,
                    name=display_name,
                ))
        
        # Shuffle items so they're not grouped by category
        random.shuffle(items)
        
        # Store for validation
        self._session["current_items"] = items
        
        return GroupingRoundResponse(
            round_number=self._session["current_round"],
            total_rounds=self._session["total_rounds"],
            items=items,
            categories=self.CATEGORIES,
        )
    
    def validate_grouping(
        self, 
        assignments: Dict[str, str],
        time_spent: float
    ) -> GroupingSubmitResponse:
        """
        Validate user's grouping assignments.
        
        Args:
            assignments: Dict mapping item_id -> user's chosen category
            time_spent: Time in seconds the user took
            
        Returns:
            GroupingSubmitResponse with accuracy and per-item details
        """
        current_items = self._session.get("current_items", [])
        
        if not current_items:
            raise ValueError("No active round. Call /round first.")
        
        # Build lookup: item_id -> correct category
        correct_map = {item.id: item for item in current_items}
        
        details = []
        correct_count = 0
        total_count = len(current_items)
        
        for item in current_items:
            user_category = assignments.get(item.id, "unassigned")
            is_correct = user_category.lower() == item.label.lower()
            
            if is_correct:
                correct_count += 1
            
            details.append(GroupingItemResult(
                item_id=item.id,
                item_name=item.name,
                user_category=user_category,
                correct_category=item.label,
                is_correct=is_correct,
            ))
        
        accuracy = correct_count / max(total_count, 1)
        is_all_correct = correct_count == total_count
        
        # Update session metrics
        self._session["rounds_completed"] += 1
        self._session["total_accuracy"] += accuracy
        self._session["total_time"] += time_spent
        
        # Generate feedback
        message, pixy_emotion = self._generate_feedback(accuracy, time_spent, is_all_correct)
        
        # Log performance (placeholder for database logging)
        self._log_performance(accuracy, time_spent)
        
        return GroupingSubmitResponse(
            is_correct=is_all_correct,
            accuracy=round(accuracy, 2),
            time_spent=round(time_spent, 1),
            correct_count=correct_count,
            total_count=total_count,
            details=details,
            message=message,
            pixy_emotion=pixy_emotion,
            difficulty_level=self._get_difficulty_level(),
        )
    
    def _generate_feedback(
        self, accuracy: float, time_spent: float, is_all_correct: bool
    ) -> Tuple[str, str]:
        """Generate user-friendly feedback based on performance."""
        if is_all_correct:
            if time_spent < 15:
                return ("Lightning fast sorting! Perfect score! ⚡🎉", "happy")
            elif time_spent < 30:
                return ("Perfect sorting! You're a natural organizer! 🎉", "happy")
            else:
                return ("All correct! Great categorization! 🌟", "happy")
        elif accuracy >= 0.8:
            return ("Almost perfect! Just a few items were in the wrong group. Try again! 💪", "encouraging")
        elif accuracy >= 0.5:
            return ("Good effort! Some items need to be moved. Check the categories carefully! 🤔", "thinking")
        else:
            return ("Let's try again! Think about what group each item belongs to. You can do it! 🌈", "encouraging")
    
    def _get_difficulty_level(self) -> int:
        """
        Adaptive difficulty based on past performance.
        Returns 1 (easy), 2 (medium), or 3 (hard).
        
        Placeholder: can be enhanced with user history from database.
        """
        rounds_done = self._session.get("rounds_completed", 0)
        if rounds_done == 0:
            return 1
        
        avg_accuracy = self._session["total_accuracy"] / rounds_done
        avg_time = self._session["total_time"] / rounds_done
        
        # High accuracy + fast = increase difficulty
        if avg_accuracy >= 0.9 and avg_time < 20:
            return 3
        elif avg_accuracy >= 0.7:
            return 2
        else:
            return 1
    
    def _log_performance(self, accuracy: float, time_spent: float):
        """
        Log performance metrics. 
        Placeholder for database integration.
        
        In production, this would log to:
        - User ID
        - Mission ID
        - Round number
        - Accuracy
        - Time spent
        - Difficulty level
        - Timestamp
        """
        round_num = self._session["current_round"]
        difficulty = self._get_difficulty_level()
        print(f"[GROUPING] Round {round_num}: accuracy={accuracy:.2f}, "
              f"time={time_spent:.1f}s, difficulty={difficulty}")
    
    def get_image_path(self, category: str, filename: str) -> Path:
        """Get the file path for a grouping item image."""
        return self.DATASET_PATH / category / filename
    
    def is_mission_complete(self) -> bool:
        """Check if all rounds are done."""
        return self._session["rounds_completed"] >= self._session["total_rounds"]
    
    def get_mission_summary(self) -> dict:
        """Get overall mission performance summary."""
        rounds = self._session["rounds_completed"]
        if rounds == 0:
            return {"avg_accuracy": 0, "total_time": 0, "rounds": 0}
        
        return {
            "avg_accuracy": round(self._session["total_accuracy"] / rounds, 2),
            "total_time": round(self._session["total_time"], 1),
            "rounds": rounds,
        }


# Singleton instance
_service_instance = None

def get_grouping_service() -> GroupingMissionService:
    """Get or create the grouping service singleton."""
    global _service_instance
    if _service_instance is None:
        _service_instance = GroupingMissionService()
    return _service_instance
