import random
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from .schemas import (
    VocabImage,
    VocabQuestion,
    VocabStartResponse,
    VocabAnswerResponse,
    VocabAnswerResult,
    VocabProgressResponse,
)


class VocabularyMissionService:
    """
    Service for the Vocabulary Mission — match words to images.
    
    Provides word-image pairs, validates answers, tracks progress,
    and includes hooks for adaptive difficulty.
    """
    
    # ═══════════════════════════════════════════════════════════════════════
    # QUESTION BANK: (word, label, image_filename)
    # The label is the lowercase identifier, filename is {label}.png
    # ═══════════════════════════════════════════════════════════════════════
    
    WORD_BANK = [
        # Animals
        ("Cat", "cat", "cat.png"),
        ("Dog", "dog", "dog.png"),
        ("Bird", "bird", "bird.png"),
        ("Fish", "fish", "fish.png"),
        ("Rabbit", "rabbit", "rabbit.png"),
        # Food
        ("Apple", "apple", "apple.png"),
        ("Banana", "banana", "banana.png"),
        ("Bread", "bread", "bread.png"),
        ("Milk", "milk", "milk.png"),
        ("Cookie", "cookie", "cookie.png"),
        # Objects
        ("Book", "book", "book.png"),
        ("Ball", "ball", "ball.png"),
        ("Car", "car", "car.png"),
        ("House", "house", "house.png"),
        ("Star", "star", "star.png"),
    ]
    
    DATASET_PATH = Path(__file__).parent.parent.parent / "Resources" / "Vocabulary Dataset"
    
    # Mission configuration
    QUESTIONS_PER_MISSION = 8
    OPTIONS_PER_QUESTION = 4  # Number of image choices per question
    
    def __init__(self):
        self._session: Dict = {}
        self._reset_session()
    
    def _reset_session(self):
        """Reset mission session state."""
        self._session = {
            "questions": [],           # List of generated VocabQuestion
            "answers": [],             # List of VocabAnswerResult
            "current_index": 0,
            "total_questions": 0,
            "correct_count": 0,
            "incorrect_words": [],     # Words answered incorrectly (for repetition)
        }
    
    def start_mission(self, num_questions: int = 0) -> VocabStartResponse:
        """
        Start a new vocabulary mission.
        Picks random words and generates distractor options.
        """
        self._reset_session()
        
        if num_questions <= 0:
            num_questions = self.QUESTIONS_PER_MISSION
        
        # Adjust based on difficulty
        difficulty = self._get_difficulty()
        options_count = min(self.OPTIONS_PER_QUESTION + difficulty - 1, 6)
        
        # Pick random words for this mission
        selected = random.sample(self.WORD_BANK, min(num_questions, len(self.WORD_BANK)))
        
        questions = []
        for idx, (word, label, filename) in enumerate(selected):
            # Correct image always gets ID based on index
            correct_id = idx * 100 + 1
            
            # Build image list: correct + distractors
            images = [
                VocabImage(
                    id=correct_id,
                    url=f"/vocabulary/image/{filename}",
                    label=label,
                )
            ]
            
            # Pick distractors from other words
            distractors = [
                (w, l, f) for (w, l, f) in self.WORD_BANK 
                if l != label
            ]
            distractor_picks = random.sample(
                distractors, 
                min(options_count - 1, len(distractors))
            )
            
            for d_idx, (d_word, d_label, d_filename) in enumerate(distractor_picks):
                images.append(VocabImage(
                    id=idx * 100 + d_idx + 2,
                    url=f"/vocabulary/image/{d_filename}",
                    label=d_label,
                ))
            
            # Shuffle images so correct isn't always first
            random.shuffle(images)
            
            questions.append(VocabQuestion(
                word=word,
                images=images,
                correctImageId=correct_id,
            ))
        
        self._session["questions"] = questions
        self._session["total_questions"] = len(questions)
        
        return VocabStartResponse(
            missionId=7,  # Vocabulary mission ID
            questions=questions,
            totalQuestions=len(questions),
            message="Select the image that matches each word! 📖",
        )
    
    def validate_answer(
        self, 
        question_index: int, 
        selected_image_id: int
    ) -> VocabAnswerResponse:
        """
        Validate a user's answer for a specific question.
        
        Args:
            question_index: index of the question (0-based)
            selected_image_id: ID of the image the user selected
        """
        questions = self._session.get("questions", [])
        
        if not questions:
            raise ValueError("No active mission. Call /start first.")
        
        if question_index < 0 or question_index >= len(questions):
            raise ValueError(f"Invalid question index: {question_index}")
        
        question = questions[question_index]
        is_correct = selected_image_id == question.correctImageId
        
        # Save result
        result = VocabAnswerResult(
            word=question.word,
            selectedImageId=selected_image_id,
            correctImageId=question.correctImageId,
            correct=is_correct,
        )
        
        # Avoid duplicate answers for same question
        while len(self._session["answers"]) <= question_index:
            self._session["answers"].append(None)
        self._session["answers"][question_index] = result
        
        # Update counts
        self._session["correct_count"] = sum(
            1 for a in self._session["answers"] if a and a.correct
        )
        
        if not is_correct:
            if question.word not in self._session["incorrect_words"]:
                self._session["incorrect_words"].append(question.word)
        
        # Count completed
        completed = sum(1 for a in self._session["answers"] if a is not None)
        
        # Generate feedback
        message, encouragement = self._generate_feedback(is_correct, question.word)
        
        # Log for analytics
        self._log_answer(question.word, is_correct, question_index)
        
        return VocabAnswerResponse(
            success=True,
            correct=is_correct,
            correctImageId=question.correctImageId,
            message=message,
            encouragement=encouragement,
            progress={
                "completed": completed,
                "total": self._session["total_questions"],
            },
        )
    
    def get_progress(self) -> VocabProgressResponse:
        """Get current mission progress and analytics."""
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
            incorrectWords=self._session.get("incorrect_words", []),
            masteryScore=round(mastery, 2),
        )
    
    def _generate_feedback(self, is_correct: bool, word: str) -> Tuple[str, str]:
        """
        Generate user-facing feedback + mascot encouragement.
        Returns (message, encouragement_bubble).
        """
        if is_correct:
            messages = [
                (f"That's right! '{word}' is correct! ✅", "Pixy is impressed! 🌟"),
                (f"Perfect match for '{word}'! 🎯", "You're a vocabulary star! ⭐"),
                (f"Correct! You know '{word}' well! 💚", "Keep it up! 🚀"),
                (f"'{word}' — nailed it! 🏆", "Amazing memory! 🧠"),
            ]
        else:
            messages = [
                (f"Not quite! Take a look at the correct image for '{word}'.", "Don't worry, you'll get it next time! 💪"),
                (f"Oops! '{word}' matches a different image.", "Learning is all about trying! 🌈"),
                (f"Almost! The right answer is shown above.", "Every mistake helps you learn! 📚"),
                (f"Not this time for '{word}', but you're doing great!", "Pixy believes in you! 🤗"),
            ]
        
        return random.choice(messages)
    
    def _get_difficulty(self) -> int:
        """
        Adaptive difficulty placeholder.
        Returns 1 (easy: 4 options), 2 (medium: 5), 3 (hard: 6).
        """
        answers = [a for a in self._session.get("answers", []) if a is not None]
        if len(answers) < 3:
            return 1
        
        recent = answers[-5:]
        recent_accuracy = sum(1 for a in recent if a.correct) / len(recent)
        
        if recent_accuracy >= 0.9:
            return 3
        elif recent_accuracy >= 0.6:
            return 2
        return 1
    
    def _should_repeat_word(self, word: str) -> bool:
        """
        Adaptive hook: should this word be repeated in future sessions?
        Placeholder for spaced repetition integration.
        """
        return word in self._session.get("incorrect_words", [])
    
    def _calculate_mastery(self, accuracy: float, completed: int, total: int) -> float:
        """
        Calculate a mastery score (0.0 - 1.0).
        Placeholder for more sophisticated mastery algorithms.
        """
        if total == 0:
            return 0.0
        completion_factor = completed / total
        return accuracy * completion_factor
    
    def _log_answer(self, word: str, is_correct: bool, question_index: int):
        """
        Log answer for analytics.
        Placeholder for database persistence.
        
        In production would save:
        - User ID, Mission ID, Word, Selected answer
        - Correct/Incorrect, Timestamp, Difficulty level
        """
        status = "✓" if is_correct else "✗"
        print(f"[VOCABULARY] Q{question_index + 1}: '{word}' {status}")
    
    def get_image_path(self, filename: str) -> Path:
        """Get file path for a vocabulary image."""
        return self.DATASET_PATH / filename


# ═══════════════════════════════════════════════════════════════════════
# Singleton
# ═══════════════════════════════════════════════════════════════════════

_service_instance = None

def get_vocabulary_service() -> VocabularyMissionService:
    """Get or create the vocabulary service singleton."""
    global _service_instance
    if _service_instance is None:
        _service_instance = VocabularyMissionService()
    return _service_instance
