import random
import uuid
from typing import List, Dict, Tuple, Optional
from .schemas import (
    PatternItem,
    PatternStartResponse,
    PatternResultResponse,
    PatternProgressResponse,
)

class PatternMissionService:
    """
    Service for the Pattern Mission — "Complete the Pattern"
    Generates logical sequences of shapes and colors.
    """
    
    # ═══════════════════════════════════════════════════════════════════════
    # CONSTANTS
    # ═══════════════════════════════════════════════════════════════════════
    
    SHAPES = ["circle", "square", "triangle", "star"]
    COLORS = [
        {"name": "red", "hex": "F44336"},
        {"name": "blue", "hex": "2196F3"},
        {"name": "green", "hex": "4CAF50"},
        {"name": "yellow", "hex": "FFEB3B"},
        {"name": "orange", "hex": "FF9800"},
        {"name": "purple", "hex": "9C27B0"},
    ]
    
    ROUNDS_PER_MISSION = 5
    
    def __init__(self):
        self._session: Dict = {}
        self._reset_session()
    
    def _reset_session(self):
        """Reset mission session state."""
        self._session = {
            "current_round": 0,
            "total_rounds": self.ROUNDS_PER_MISSION,
            "results": [],
            "difficulty": 1,
            "current_pattern": None,
            "correct_option": None,
        }
    
    def start_mission(self) -> PatternStartResponse:
        """Start a new pattern mission."""
        self._reset_session()
        return self._generate_round()
    
    def get_next_round(self) -> PatternStartResponse:
        """Get the next pattern round."""
        self._session["current_round"] += 1
        return self._generate_round()
        
    def _generate_round(self) -> PatternStartResponse:
        """Generate a pattern sequence based on current difficulty."""
        difficulty = self._session["difficulty"]
        
        # 1. Generate the full logical sequence
        full_sequence, rule_desc = self._generate_sequence(difficulty)
        
        # 2. Split into visible sequence and the "next" item (answer)
        # Visible length: usually 4-6 items
        visible_count = random.randint(4, 5)
        # Ensure visible sequence is long enough but leaves room for answer
        if len(full_sequence) <= visible_count:
             # Extend sequence if too short
             full_sequence = (full_sequence * 2)[:visible_count + 1]
             
        visible_sequence = full_sequence[:visible_count]
        correct_item = full_sequence[visible_count]
        
        # 3. Generate options (1 correct + distractors)
        options = self._generate_options(correct_item, difficulty)
        
        # 4. Store state
        self._session["current_pattern"] = full_sequence
        self._session["correct_option"] = correct_item
        
        return PatternStartResponse(
            missionId=1,
            sequence=visible_sequence,
            options=options,
            difficulty=difficulty,
            round=self._session["current_round"] + 1,
            totalRounds=self._session["total_rounds"],
            instruction="Look at the pattern. What comes next?",
        )
    
    def _generate_sequence(self, difficulty: int) -> Tuple[List[PatternItem], str]:
        """
        Generate a sequence of PatternItems based on difficulty rules.
        Returns (sequence, rule_description)
        """
        # Pick random shapes and colors pool for this round
        shapes = random.sample(self.SHAPES, k=min(difficulty + 1, len(self.SHAPES)))
        colors = random.sample(self.COLORS, k=min(difficulty + 2, len(self.COLORS)))
        
        # Define pattern templates based on difficulty
        # A, B, C are indices in the chosen pool
        
        if difficulty == 1:
            # Simple Alternating: A B A B
            # Rule: Change Color OR Shape (but consistent)
            mode = random.choice(["color", "shape"])
            pattern_type = "ABAB"
            
            base_shape = shapes[0]
            base_color = colors[0]
            
            seq_items = []
            for i in range(10):
                idx = i % 2
                if mode == "color":
                    # Same shape, alternating colors
                    item = self._create_item(base_shape, colors[idx])
                else:
                    # Same color, alternating shapes
                    item = self._create_item(shapes[idx], base_color)
                seq_items.append(item)
                
            return seq_items, f"Alternating {mode}"
            
        elif difficulty == 2:
            # 3-Cycle: A B C A B C
            # Rule: Rotating 3 items
            pattern_type = "ABC"
            
            # Create 3 distinct items
            items = [
                self._create_item(random.choice(shapes), random.choice(colors))
                for _ in range(3)
            ]
            
            seq_items = []
            for i in range(10):
                idx = i % 3
                # Clone item with new ID
                template = items[idx]
                seq_items.append(self._create_item(template.shape, {"name": "", "hex": template.color})) # hacky color passing
                # Actually _create_item needs dict for color, wrapper function might be better
                # Let's clean this up:
                seq_items.append(PatternItem(
                    id=str(uuid.uuid4()),
                    shape=template.shape,
                    color=template.color
                ))
            
            return seq_items, "ABC Pattern"
            
        else:
            # Difficulty 3+: Complex
            # A A B A A B  or  A B B A B B
            pattern_rules = ["AAB", "ABB", "AABB"]
            rule = random.choice(pattern_rules)
            
            # Create 2 base items
            item_a = self._create_item(random.choice(shapes), random.choice(colors))
            item_b = self._create_item(random.choice(shapes), random.choice(colors))
            while item_b.shape == item_a.shape and item_b.color == item_a.color:
                 item_b = self._create_item(random.choice(shapes), random.choice(colors))
            
            seq_items = []
            pattern_str = ""
            if rule == "AAB":
                pattern_str = "001" * 4
            elif rule == "ABB":
                pattern_str = "011" * 4
            else:
                pattern_str = "0011" * 3
                
            for char in pattern_str:
                template = item_a if char == '0' else item_b
                seq_items.append(PatternItem(
                    id=str(uuid.uuid4()),
                    shape=template.shape,
                    color=template.color
                ))
                
            return seq_items, f"{rule} Pattern"

    def _create_item(self, shape: str, color: Dict) -> PatternItem:
        return PatternItem(
            id=str(uuid.uuid4()),
            shape=shape,
            color=color["hex"] # Send hex to frontend
        )
        
    def _generate_options(self, correct: PatternItem, difficulty: int) -> List[PatternItem]:
        """Generate 3 distinct options, one being correct."""
        options = [correct]
        
        # Generate distractors
        while len(options) < 3:
            distractor = self._create_item(
                random.choice(self.SHAPES),
                random.choice(self.COLORS)
            )
            
            # Check for duplicate visible appearance (shape + color)
            is_dup = False
            for opt in options:
                if opt.shape == distractor.shape and opt.color == distractor.color:
                    is_dup = True
                    break
            
            if not is_dup:
                options.append(distractor)
        
        random.shuffle(options)
        return options

    def validate_answer(self, selected_id: str) -> PatternResultResponse:
        """Check if the selected option is correct."""
        correct_item = self._session["correct_option"]
        if not correct_item:
             return PatternResultResponse(
                success=False, correct=False, correctOptionId="",
                message="Error: No active round", newDifficulty=1, completionProgress=0.0
            )

        # Find selected item in options? 
        # Actually we just need to know if selected_id matches correct_item.id
        # WAIT: The options are regenerated with NEW IDs in `_start_mission`? 
        # No, `options` contains the `correct_item` object itself, so IDs match.
        
        is_correct = (selected_id == correct_item.id)
        
        # Update session
        self._session["results"].append(is_correct)
        
        # Adjust difficulty
        if is_correct:
             # Increase difficulty every 2 consecutive correct answers?
             # For now, simple: correct -> keep/increase, incorrect -> decrease
             if self._session["difficulty"] < 3:
                 self._session["difficulty"] += 1
        else:
             self._session["difficulty"] = max(1, self._session["difficulty"] - 1)
             
        # Progress
        completed = len(self._session["results"])
        total = self._session["total_rounds"]
        
        message = random.choice([
            "That's right! You found the pattern! 🧩",
            "Great job! 🌟",
            "Correct! Keep it up! 🚀"
        ]) if is_correct else "Not quite. Look at the colors and shapes again. 👀"

        return PatternResultResponse(
            success=True,
            correct=is_correct,
            correctOptionId=correct_item.id,
            message=message,
            newDifficulty=self._session["difficulty"],
            completionProgress=completed / total
        )

    def get_progress(self) -> PatternProgressResponse:
        results = self._session["results"]
        total_correct = sum(1 for r in results if r)
        accuracy = total_correct / max(len(results), 1)
        
        return PatternProgressResponse(
            completed=len(results),
            total=self._session["total_rounds"],
            accuracy=accuracy,
            currentDifficulty=self._session["difficulty"]
        )

# ═══════════════════════════════════════════════════════════════════════
# Singleton
# ═══════════════════════════════════════════════════════════════════════

_service_instance = None

def get_pattern_service() -> PatternMissionService:
    global _service_instance
    if _service_instance is None:
        _service_instance = PatternMissionService()
    return _service_instance
