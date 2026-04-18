"""
Complete-the-Pattern mission service.

Kid-friendly emoji-based pattern recognition. Each session pre-generates 5
rounds with a gentle difficulty curve (easy → hard). Each round offers 3
choices; the backend validates answers on /answer.

Pattern rules used:
- Difficulty 1 (ABAB): alternate two items
- Difficulty 2 (ABCABC): rotate three items
- Difficulty 3 (AAB / ABB / AABB): more complex recurring groups
"""
import random
from typing import Dict, List, Tuple

from .schemas import (
    PatternAnswerResponse,
    PatternItem,
    PatternProgress,
    PatternProgressResponse,
    PatternQuestion,
    PatternStartResponse,
)


MISSION_ID = -9
TOTAL_ROUNDS = 5

# Difficulty progression — easy → hard.
DIFFICULTY_PLAN: List[int] = [1, 1, 2, 2, 3]

# Themed emoji pools with bilingual labels.
# Each entry: {"emoji", "labelEn", "labelRo"}.
EMOJI_THEMES: Dict[str, List[Dict[str, str]]] = {
    "fruits": [
        {"emoji": "🍎", "labelEn": "apple", "labelRo": "măr"},
        {"emoji": "🍌", "labelEn": "banana", "labelRo": "banană"},
        {"emoji": "🍇", "labelEn": "grapes", "labelRo": "struguri"},
        {"emoji": "🍓", "labelEn": "strawberry", "labelRo": "căpșună"},
        {"emoji": "🍊", "labelEn": "orange", "labelRo": "portocală"},
        {"emoji": "🍉", "labelEn": "watermelon", "labelRo": "pepene"},
    ],
    "animals": [
        {"emoji": "🐶", "labelEn": "dog", "labelRo": "câine"},
        {"emoji": "🐱", "labelEn": "cat", "labelRo": "pisică"},
        {"emoji": "🐰", "labelEn": "rabbit", "labelRo": "iepure"},
        {"emoji": "🦊", "labelEn": "fox", "labelRo": "vulpe"},
        {"emoji": "🐻", "labelEn": "bear", "labelRo": "urs"},
        {"emoji": "🐼", "labelEn": "panda", "labelRo": "panda"},
    ],
    "shapes": [
        {"emoji": "⭐", "labelEn": "star", "labelRo": "stea"},
        {"emoji": "🟦", "labelEn": "blue square", "labelRo": "pătrat albastru"},
        {"emoji": "🔴", "labelEn": "red circle", "labelRo": "cerc roșu"},
        {"emoji": "🟢", "labelEn": "green circle", "labelRo": "cerc verde"},
        {"emoji": "🟣", "labelEn": "purple circle", "labelRo": "cerc violet"},
        {"emoji": "🔶", "labelEn": "diamond", "labelRo": "romb"},
    ],
    "vehicles": [
        {"emoji": "🚗", "labelEn": "car", "labelRo": "mașină"},
        {"emoji": "🚌", "labelEn": "bus", "labelRo": "autobuz"},
        {"emoji": "🚲", "labelEn": "bike", "labelRo": "bicicletă"},
        {"emoji": "🛴", "labelEn": "scooter", "labelRo": "trotinetă"},
        {"emoji": "✈️", "labelEn": "plane", "labelRo": "avion"},
        {"emoji": "🚀", "labelEn": "rocket", "labelRo": "rachetă"},
    ],
    "weather": [
        {"emoji": "☀️", "labelEn": "sun", "labelRo": "soare"},
        {"emoji": "⛅", "labelEn": "cloudy", "labelRo": "înnorat"},
        {"emoji": "🌧️", "labelEn": "rain", "labelRo": "ploaie"},
        {"emoji": "❄️", "labelEn": "snow", "labelRo": "zăpadă"},
        {"emoji": "🌈", "labelEn": "rainbow", "labelRo": "curcubeu"},
        {"emoji": "⚡", "labelEn": "lightning", "labelRo": "fulger"},
    ],
}


def _mk_item(item_id: int, src: Dict[str, str]) -> PatternItem:
    return PatternItem(
        id=item_id,
        emoji=src["emoji"],
        labelEn=src["labelEn"],
        labelRo=src["labelRo"],
    )


class PatternMissionService:
    """
    Stateful service that keeps the generated questions per session so that
    /answer can validate against the original correct option id.

    Note: the module-level singleton is process-wide (single child on
    device), matching the existing vocabulary / animals services.
    """

    def __init__(self) -> None:
        self._questions: List[PatternQuestion] = []
        self._correct_ids: List[int] = []
        self._results: List[bool] = []

    # ─────────────────────────────────────────────────────────────
    # Public API
    # ─────────────────────────────────────────────────────────────

    def start_mission(self) -> PatternStartResponse:
        """Generate a fresh set of 5 rounds and return them to the client."""
        self._questions = []
        self._correct_ids = []
        self._results = []

        # Pick a shuffled theme per round, with replacement if we run out.
        theme_names = list(EMOJI_THEMES.keys())
        random.shuffle(theme_names)
        while len(theme_names) < len(DIFFICULTY_PLAN):
            theme_names.append(random.choice(list(EMOJI_THEMES.keys())))

        for round_idx, difficulty in enumerate(DIFFICULTY_PLAN):
            theme = theme_names[round_idx]
            question, correct_id = self._generate_round(
                round_idx=round_idx,
                difficulty=difficulty,
                theme=theme,
            )
            self._questions.append(question)
            self._correct_ids.append(correct_id)

        return PatternStartResponse(
            missionId=MISSION_ID,
            totalRounds=TOTAL_ROUNDS,
            questions=self._questions,
        )

    def validate_answer(
        self, question_index: int, selected_option_id: int
    ) -> PatternAnswerResponse:
        """Check the submitted answer for a given round."""
        if not (0 <= question_index < len(self._questions)):
            # Unknown round — fail soft with a safe payload.
            return PatternAnswerResponse(
                success=False,
                correct=False,
                correctOptionId=-1,
                progress=PatternProgress(
                    completed=len(self._results), total=TOTAL_ROUNDS
                ),
            )

        correct_id = self._correct_ids[question_index]
        is_correct = selected_option_id == correct_id

        # Extend the results array so index == question_index works cleanly
        # even if the client skips around.
        while len(self._results) <= question_index:
            self._results.append(False)
        self._results[question_index] = is_correct

        return PatternAnswerResponse(
            success=True,
            correct=is_correct,
            correctOptionId=correct_id,
            progress=PatternProgress(
                completed=sum(1 for _ in self._results),
                total=TOTAL_ROUNDS,
            ),
        )

    def get_progress(self) -> PatternProgressResponse:
        completed = len(self._results)
        correct = sum(1 for r in self._results if r)
        accuracy = correct / completed if completed else 0.0
        return PatternProgressResponse(
            completed=completed,
            total=TOTAL_ROUNDS,
            correctCount=correct,
            accuracy=accuracy,
        )

    # ─────────────────────────────────────────────────────────────
    # Round generation
    # ─────────────────────────────────────────────────────────────

    def _generate_round(
        self,
        round_idx: int,
        difficulty: int,
        theme: str,
    ) -> Tuple[PatternQuestion, int]:
        pool = EMOJI_THEMES[theme]

        if difficulty == 1:
            # ABAB → show 4 alternating items, next is A. (A, B, A, B | A)
            a, b = random.sample(pool, 2)
            pattern = [a, b, a, b, a]
            rule = "ABAB"
        elif difficulty == 2:
            # ABCABC → show 5, next is C.
            a, b, c = random.sample(pool, 3)
            pattern = [a, b, c, a, b, c]
            rule = "ABCABC"
        else:
            choice = random.choice(["AAB", "ABB", "AABB"])
            a, b = random.sample(pool, 2)
            if choice == "AAB":
                pattern = [a, a, b, a, a, b]
                rule = "AABAAB"
            elif choice == "ABB":
                pattern = [a, b, b, a, b, b]
                rule = "ABBABB"
            else:
                pattern = [a, a, b, b, a, a, b, b]
                rule = "AABB"

        visible_src = pattern[:-1]
        correct_src = pattern[-1]

        # Stable per-round ID scheme so the frontend can compare selections:
        # - base = (round_idx + 1) * 100
        # - visible items use base + 10 + i
        # - options use base, base + 1, base + 2 (correct is always `base`)
        base = (round_idx + 1) * 100
        visible_items = [
            _mk_item(base + 10 + i, src) for i, src in enumerate(visible_src)
        ]

        # Pick 2 distractors that are distinct from the correct emoji.
        distractor_pool = [p for p in pool if p["emoji"] != correct_src["emoji"]]
        random.shuffle(distractor_pool)
        distractors = distractor_pool[:2]

        options: List[PatternItem] = [_mk_item(base, correct_src)]
        for j, src in enumerate(distractors):
            options.append(_mk_item(base + 1 + j, src))
        random.shuffle(options)

        question = PatternQuestion(
            index=round_idx,
            theme=theme,
            rule=rule,
            difficulty=difficulty,
            sequence=visible_items,
            options=options,
        )
        return question, base


# ═══════════════════════════════════════════════════════════════════
# Singleton
# ═══════════════════════════════════════════════════════════════════

_service_instance: PatternMissionService | None = None


def get_pattern_service() -> PatternMissionService:
    global _service_instance
    if _service_instance is None:
        _service_instance = PatternMissionService()
    return _service_instance
