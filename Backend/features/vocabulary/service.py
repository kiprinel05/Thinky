"""
Word Match mission — match a word to the correct emoji image.

Everything is returned bilingual (EN + RO). The frontend picks the active
language from LanguageService. Feedback strings are generated client-side so
we don't have to round-trip translations through the backend.
"""
from __future__ import annotations

import random
from typing import Dict, List, Tuple

from .schemas import (
    VocabAnswerRequest,
    VocabAnswerResponse,
    VocabAnswerResult,
    VocabImage,
    VocabProgressResponse,
    VocabQuestion,
    VocabStartResponse,
)


# ═══════════════════════════════════════════════════════════════════════════
# WORD BANK
# Each entry: (word_en, word_ro, emoji, category)
# Curated to have:
#   • instantly-recognizable emoji on every platform
#   • clean 1:1 meaning (no ambiguity between 🐶 and 🐕 etc.)
#   • even distribution across categories so distractors feel fair
# ═══════════════════════════════════════════════════════════════════════════

WORD_BANK: List[Tuple[str, str, str, str]] = [
    # Animals — 6
    ("Cat",     "Pisică",  "🐱", "animal"),
    ("Dog",     "Câine",   "🐶", "animal"),
    ("Bird",    "Pasăre",  "🐦", "animal"),
    ("Fish",    "Pește",   "🐟", "animal"),
    ("Rabbit",  "Iepure",  "🐰", "animal"),
    ("Bear",    "Urs",     "🐻", "animal"),
    # Food — 5
    ("Apple",   "Măr",     "🍎", "food"),
    ("Banana",  "Banană",  "🍌", "food"),
    ("Pizza",   "Pizza",   "🍕", "food"),
    ("Milk",    "Lapte",   "🥛", "food"),
    ("Cookie",  "Biscuit", "🍪", "food"),
    # Objects — 4
    ("Book",    "Carte",   "📖", "object"),
    ("Ball",    "Minge",   "⚽", "object"),
    ("Car",     "Mașină",  "🚗", "object"),
    ("House",   "Casă",    "🏠", "object"),
    # Nature — 3
    ("Sun",     "Soare",   "☀️", "nature"),
    ("Tree",    "Copac",   "🌳", "nature"),
    ("Flower",  "Floare",  "🌸", "nature"),
]


class VocabularyMissionService:
    """Generates rounds of word→emoji matching and validates answers."""

    QUESTIONS_PER_MISSION = 8
    OPTIONS_PER_QUESTION = 4

    def __init__(self) -> None:
        self._session: Dict = {}
        self._reset_session()

    # ──────────────────────────────────────────────────────────────────
    # Session plumbing
    # ──────────────────────────────────────────────────────────────────

    def _reset_session(self) -> None:
        self._session = {
            "questions": [],
            "answers": [],
            "current_index": 0,
            "total_questions": 0,
            "correct_count": 0,
            "incorrect_words_en": [],
        }

    # ──────────────────────────────────────────────────────────────────
    # Public API
    # ──────────────────────────────────────────────────────────────────

    def start_mission(self, num_questions: int = 0) -> VocabStartResponse:
        """Start a fresh round with a randomly sampled set of words."""
        self._reset_session()

        if num_questions <= 0:
            num_questions = self.QUESTIONS_PER_MISSION
        num_questions = min(num_questions, len(WORD_BANK))

        difficulty = self._get_difficulty()
        options_count = min(
            self.OPTIONS_PER_QUESTION + max(0, difficulty - 1),
            6,
        )

        selected = random.sample(WORD_BANK, num_questions)

        questions: List[VocabQuestion] = []
        for q_idx, (word_en, word_ro, emoji, category) in enumerate(selected):
            correct_id = q_idx * 100 + 1
            images: List[VocabImage] = [
                VocabImage(
                    id=correct_id,
                    emoji=emoji,
                    labelEn=word_en.lower(),
                    labelRo=word_ro.lower(),
                )
            ]

            # Pick distractors — prefer different category so the question
            # isn't "which cat is it?" but a real concept-recognition test.
            same_cat = [w for w in WORD_BANK
                        if w[3] == category and w[0] != word_en]
            other_cat = [w for w in WORD_BANK
                         if w[3] != category]
            random.shuffle(same_cat)
            random.shuffle(other_cat)
            # Mix: ~1 same-category distractor to keep it interesting,
            # the rest from other categories.
            distractor_pool: List[Tuple[str, str, str, str]] = []
            if same_cat:
                distractor_pool.append(same_cat[0])
            distractor_pool.extend(other_cat)
            distractors = distractor_pool[: options_count - 1]

            for d_idx, (d_en, d_ro, d_emoji, _d_cat) in enumerate(distractors):
                images.append(VocabImage(
                    id=q_idx * 100 + d_idx + 2,
                    emoji=d_emoji,
                    labelEn=d_en.lower(),
                    labelRo=d_ro.lower(),
                ))

            random.shuffle(images)

            questions.append(VocabQuestion(
                wordEn=word_en,
                wordRo=word_ro,
                category=category,
                images=images,
                correctImageId=correct_id,
            ))

        self._session["questions"] = questions
        self._session["total_questions"] = len(questions)

        return VocabStartResponse(
            missionId=7,
            questions=questions,
            totalQuestions=len(questions),
        )

    def validate_answer(self, req: VocabAnswerRequest) -> VocabAnswerResponse:
        questions: List[VocabQuestion] = self._session.get("questions", [])
        if not questions:
            raise ValueError("No active mission. Call /start first.")
        idx = req.questionIndex
        if idx < 0 or idx >= len(questions):
            raise ValueError(f"Invalid question index: {idx}")

        question = questions[idx]
        is_correct = req.selectedImageId == question.correctImageId

        while len(self._session["answers"]) <= idx:
            self._session["answers"].append(None)
        self._session["answers"][idx] = VocabAnswerResult(
            wordEn=question.wordEn,
            wordRo=question.wordRo,
            selectedImageId=req.selectedImageId,
            correctImageId=question.correctImageId,
            correct=is_correct,
        )

        self._session["correct_count"] = sum(
            1 for a in self._session["answers"] if a and a.correct
        )
        if not is_correct and question.wordEn not in self._session["incorrect_words_en"]:
            self._session["incorrect_words_en"].append(question.wordEn)

        completed = sum(1 for a in self._session["answers"] if a is not None)

        print(f"[VOCABULARY] Q{idx + 1}: '{question.wordEn}' "
              f"{'✓' if is_correct else '✗'}")

        return VocabAnswerResponse(
            success=True,
            correct=is_correct,
            correctImageId=question.correctImageId,
            progress={
                "completed": completed,
                "total": self._session["total_questions"],
            },
        )

    def get_progress(self) -> VocabProgressResponse:
        answers = [a for a in self._session.get("answers", []) if a is not None]
        total = self._session.get("total_questions", 0)
        correct = self._session.get("correct_count", 0)
        completed = len(answers)
        accuracy = correct / max(completed, 1)
        mastery = self._calculate_mastery(accuracy, completed, total)
        return VocabProgressResponse(
            completed=completed,
            total=total,
            correctCount=correct,
            accuracy=round(accuracy, 2),
            results=answers,
            incorrectWordsEn=self._session.get("incorrect_words_en", []),
            masteryScore=round(mastery, 2),
        )

    # ──────────────────────────────────────────────────────────────────
    # Adaptive helpers
    # ──────────────────────────────────────────────────────────────────

    def _get_difficulty(self) -> int:
        """1 = easy (4 opts), 2 = medium (5), 3 = hard (6)."""
        answers = [a for a in self._session.get("answers", []) if a is not None]
        if len(answers) < 3:
            return 1
        recent = answers[-5:]
        recent_accuracy = sum(1 for a in recent if a.correct) / len(recent)
        if recent_accuracy >= 0.9:
            return 3
        if recent_accuracy >= 0.6:
            return 2
        return 1

    def _calculate_mastery(
        self, accuracy: float, completed: int, total: int
    ) -> float:
        if total == 0:
            return 0.0
        completion_factor = completed / total
        return accuracy * completion_factor


# ═══════════════════════════════════════════════════════════════════════
# Singleton
# ═══════════════════════════════════════════════════════════════════════

_service_instance: VocabularyMissionService | None = None


def get_vocabulary_service() -> VocabularyMissionService:
    global _service_instance
    if _service_instance is None:
        _service_instance = VocabularyMissionService()
    return _service_instance
