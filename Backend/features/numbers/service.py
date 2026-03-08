import random
from typing import Dict, Optional
from datetime import datetime, timezone

from features.numbers.schemas import (
    ObjectItem, NumbersStartResponse, NumbersRoundResponse,
    CountingSubmission, CountingResponse,
    DrawingResponse, NumbersProgressResponse
)
from features.numbers.digit_recognition import digit_recognition_service

# Support both old (api/) and new (features/) architecture
try:
    from features.mission.repository import MissionRepository
    from features.mission.models import Mission, MissionProgress
except ImportError:
    from models.mission_model import Mission, MissionProgress
    MissionRepository = None  # Will use direct DB access instead


# Object pools for generating counting exercises
OBJECT_POOLS = {
    "apple": {"emoji": "🍎", "type": "apple"},
    "balloon": {"emoji": "🎈", "type": "balloon"},
    "star": {"emoji": "⭐", "type": "star"},
}

# Pixy personality messages per model level
PIXY_MESSAGES = {
    "junior": {
        "guess": "Hmm… cred că sunt {n}? 🤔",
        "correct_confirmed": "Ura! Am ghicit! Mulțumesc că m-ai ajutat! 😊",
        "wrong_confirmed": "Oh, ok… atunci sunt {n}... 😕",
        "corrected": "Ohhh, am greșit? Atunci sunt {n}! Mulțumesc! 😅",
        "confused": "Sunt confuz... nu mai știu câte sunt... 😵",
        "drawing_guess": "Hmm… cred că este {n}? 🤔",
        "drawing_correct": "Am reușit! Este {n}! Mulțumesc! 😊",
        "drawing_wrong": "Oh nu, am greșit din nou... 😢",
    },
    "student": {
        "guess": "Cred că sunt {n}! 🙂",
        "correct_confirmed": "Super! Am ghicit corect! Învăț repede! 😄",
        "wrong_confirmed": "Hmm, sigur sunt {n}? Ok... 🤨",
        "corrected": "Aha, sunt {n}! Am înțeles, mulțumesc! 📝",
        "confused": "Hmm, sunt puțin confuz acum... 😕",
        "drawing_guess": "Cred că ai desenat un {n}! 🙂",
        "drawing_correct": "Da! Este un {n}! Recunosc tot mai bine! 😄",
        "drawing_wrong": "Hmm, nu sunt sigur ce ai desenat... 🤔",
    },
    "expert": {
        "guess": "Este clar! Sunt {n}! 🎉",
        "correct_confirmed": "Știam! Am învățat foarte bine! 🌟",
        "wrong_confirmed": "Hmm, chiar sunt {n}? Mă gândesc din nou... 🧐",
        "corrected": "Oh, am greșit! Sunt {n}. Mulțumesc pentru corecție! 🙏",
        "confused": "Ciudat, ceva nu se potrivește... 😐",
        "drawing_guess": "Este clar! Ai desenat numărul {n}! 🎉",
        "drawing_correct": "Perfect! Recunosc numerele foarte bine acum! 🌟",
        "drawing_wrong": "Hmm, am greșit? Mă antrenez mai mult! 💪",
    },
}

PROFESSOR_MESSAGES = {
    "wrong_count": (
        "Pixy învață din ce îl învățăm noi. "
        "Dacă îi arătăm lucruri greșite, va învăța greșit. "
        "Hai să-l ajutăm corect! Numără obiectele cu atenție."
    ),
    "wrong_drawing": (
        "Pixy nu știe ce este corect sau greșit. "
        "El învață din desenele tale. "
        "Dacă îl învățăm greșit, va recunoaște greșit."
    ),
    "model_upgrade": (
        "Bravo! Pixy a învățat suficient și a trecut la nivelul următor! "
        "AI-ul învață bine atunci când oamenii sunt atenți și răbdători. 🌟"
    ),
}

# Model configuration
MODEL_LEVELS = ["junior", "student", "expert"]
CORRECT_TO_UPGRADE = 3  # correct answers needed to upgrade model
CONFUSION_THRESHOLD = 2  # wrong confirmations before professor appears


class NumbersService:
    """
    Service for the 'Learning Numbers with Pixy' mission.
    Manages session state, Pixy's simulated AI models, and professor interventions.
    """

    # In-memory session storage (in production, use Redis or DB)
    _sessions: Dict[int, dict] = {}

    def __init__(self, mission_repository: MissionRepository):
        self.mission_repo = mission_repository

    def _get_or_create_session(self, user_id: int) -> dict:
        """Get existing session or create a new one."""
        if user_id not in self._sessions:
            self._sessions[user_id] = {
                "target_number": 0,
                "object_type": "apple",
                "model_level": "junior",
                "correct_count": 0,
                "confusion_count": 0,
                "current_part": 1,
                "rounds_completed": 0,
                "total_correct": 0,
                "pixy_guess": 0,
            }
        return self._sessions[user_id]

    def start_session(self, user_id: int) -> NumbersStartResponse:
        """Start a new numbers learning session."""
        session = self._get_or_create_session(user_id)

        # Reset session
        session["correct_count"] = 0
        session["confusion_count"] = 0
        session["model_level"] = "junior"
        session["current_part"] = 1
        session["rounds_completed"] = 0
        session["total_correct"] = 0

        # Generate first round
        target = random.randint(1, 5)
        obj_key = random.choice(list(OBJECT_POOLS.keys()))
        session["target_number"] = target
        session["object_type"] = obj_key

        objects = self._generate_objects(target, obj_key)

        return NumbersStartResponse(
            target_number=target,
            objects=objects,
            model_level=session["model_level"],
            current_part=1,
            message=f"Bună! Eu sunt Pixy! Ajută-mă să învăț câte obiecte sunt! 🤖",
        )

    def get_round(self, user_id: int) -> NumbersRoundResponse:
        """Get the current round data including Pixy's guess."""
        session = self._get_or_create_session(user_id)

        if session["target_number"] == 0:
            # Generate a new round
            target = random.randint(1, 5)
            obj_key = random.choice(list(OBJECT_POOLS.keys()))
            session["target_number"] = target
            session["object_type"] = obj_key

        target = session["target_number"]
        obj_key = session["object_type"]
        model_level = session["model_level"]
        objects = self._generate_objects(target, obj_key)

        # Pixy makes a guess based on model level
        pixy_guess = self._pixy_guess_count(target, model_level)
        session["pixy_guess"] = pixy_guess

        messages = PIXY_MESSAGES[model_level]
        pixy_message = messages["guess"].format(n=pixy_guess)

        confidence = "low" if model_level == "junior" else ("medium" if model_level == "student" else "high")

        return NumbersRoundResponse(
            target_number=target,
            objects=objects,
            pixy_guess=pixy_guess,
            pixy_message=pixy_message,
            pixy_confidence=confidence,
            model_level=model_level,
            current_part=session["current_part"],
        )

    def submit_count(self, user_id: int, submission: CountingSubmission) -> CountingResponse:
        """Process a counting answer from the child."""
        session = self._get_or_create_session(user_id)
        target = session["target_number"]
        model_level = session["model_level"]
        pixy_guess = session.get("pixy_guess", target)
        messages = PIXY_MESSAGES[model_level]

        is_correct = submission.answer == target
        show_professor = False
        professor_message = None
        model_upgraded = False
        new_model_level = None

        if submission.confirmed:
            # Child is confirming Pixy's guess
            if pixy_guess == target:
                # Pixy was right, child confirmed correctly
                session["correct_count"] += 1
                session["total_correct"] += 1
                session["confusion_count"] = 0
                pixy_message = messages["correct_confirmed"]
                pixy_emotion = "happy"
            else:
                # Pixy was wrong, child confirmed a wrong answer
                session["confusion_count"] += 1
                pixy_message = messages["wrong_confirmed"].format(n=pixy_guess)
                pixy_emotion = "confused"

                if session["confusion_count"] >= CONFUSION_THRESHOLD:
                    show_professor = True
                    professor_message = PROFESSOR_MESSAGES["wrong_count"]
                    session["confusion_count"] = 0
                    pixy_message = messages["confused"]
        else:
            # Child provided their own answer
            if is_correct:
                session["correct_count"] += 1
                session["total_correct"] += 1
                session["confusion_count"] = 0

                if pixy_guess == target:
                    pixy_message = messages["correct_confirmed"]
                    pixy_emotion = "happy"
                else:
                    pixy_message = messages["corrected"].format(n=target)
                    pixy_emotion = "happy"
            else:
                session["confusion_count"] += 1
                pixy_message = messages["wrong_confirmed"].format(n=submission.answer)
                pixy_emotion = "sad"

                if session["confusion_count"] >= CONFUSION_THRESHOLD:
                    show_professor = True
                    professor_message = PROFESSOR_MESSAGES["wrong_count"]
                    session["confusion_count"] = 0

        # Check for model upgrade
        if session["correct_count"] >= CORRECT_TO_UPGRADE:
            current_idx = MODEL_LEVELS.index(model_level)
            if current_idx < len(MODEL_LEVELS) - 1:
                new_level = MODEL_LEVELS[current_idx + 1]
                session["model_level"] = new_level
                session["correct_count"] = 0
                model_upgraded = True
                new_model_level = new_level

        session["rounds_completed"] += 1

        # Check if Part 1 is complete (expert with enough correct answers, or 15+ rounds)
        part_completed = False
        if session["model_level"] == "expert" and session["correct_count"] >= CORRECT_TO_UPGRADE:
            part_completed = True
            session["current_part"] = 2
            session["correct_count"] = 0
            session["confusion_count"] = 0
            session["model_level"] = "junior"  # Reset for Part 2

        # Generate new target for next round
        session["target_number"] = random.randint(1, 5)
        session["object_type"] = random.choice(list(OBJECT_POOLS.keys()))

        return CountingResponse(
            is_correct=is_correct or (submission.confirmed and pixy_guess == target),
            correct_answer=target,
            pixy_guess=pixy_guess,
            pixy_message=pixy_message,
            pixy_emotion=pixy_emotion,
            model_level=session["model_level"],
            correct_count=session["correct_count"],
            confusion_count=session["confusion_count"],
            show_professor=show_professor,
            professor_message=professor_message,
            model_upgraded=model_upgraded,
            new_model_level=new_model_level,
            part_completed=part_completed,
        )

    def submit_drawing(self, user_id: int, image_bytes: bytes) -> DrawingResponse:
        """Process a digit drawing from the child."""
        session = self._get_or_create_session(user_id)
        model_level = session["model_level"]
        target = session["target_number"]
        messages = PIXY_MESSAGES[model_level]

        if target == 0:
            target = random.randint(1, 5)
            session["target_number"] = target

        # Recognize the digit
        guessed_digit, confidence = digit_recognition_service.recognize(
            image_bytes, model_level
        )

        is_correct = guessed_digit == target
        show_professor = False
        professor_message = None
        professor_hint = None
        model_upgraded = False
        new_model_level = None

        if is_correct:
            session["correct_count"] += 1
            session["total_correct"] += 1
            session["confusion_count"] = 0
            pixy_message = messages["drawing_correct"]
            pixy_emotion = "happy"
        else:
            session["confusion_count"] += 1
            pixy_message = messages["drawing_guess"].format(n=guessed_digit)
            pixy_emotion = "thinking"

            if session["confusion_count"] >= CONFUSION_THRESHOLD:
                show_professor = True
                professor_message = PROFESSOR_MESSAGES["wrong_drawing"]
                professor_hint = digit_recognition_service.get_hint(target)
                session["confusion_count"] = 0

        # Check for model upgrade
        if session["correct_count"] >= CORRECT_TO_UPGRADE:
            current_idx = MODEL_LEVELS.index(model_level)
            if current_idx < len(MODEL_LEVELS) - 1:
                new_level = MODEL_LEVELS[current_idx + 1]
                session["model_level"] = new_level
                session["correct_count"] = 0
                model_upgraded = True
                new_model_level = new_level

        session["rounds_completed"] += 1

        # Check if Part 2 is complete
        part_completed = False
        if session["model_level"] == "expert" and session["correct_count"] >= CORRECT_TO_UPGRADE:
            part_completed = True
            self._complete_mission(user_id, session)

        # Generate new target for next round
        session["target_number"] = random.randint(1, 5)

        return DrawingResponse(
            guessed_digit=guessed_digit,
            confidence=confidence,
            is_correct=is_correct,
            target_digit=target,
            pixy_message=pixy_message,
            pixy_emotion=pixy_emotion,
            model_level=session["model_level"],
            correct_count=session["correct_count"],
            confusion_count=session["confusion_count"],
            show_professor=show_professor,
            professor_message=professor_message,
            professor_hint=professor_hint,
            model_upgraded=model_upgraded,
            new_model_level=new_model_level,
            part_completed=part_completed,
        )

    def get_progress(self, user_id: int) -> NumbersProgressResponse:
        """Get current session progress."""
        session = self._get_or_create_session(user_id)

        total_rounds = max(session["rounds_completed"], 1)
        score = (session["total_correct"] / total_rounds) * 100

        return NumbersProgressResponse(
            current_part=session["current_part"],
            model_level=session["model_level"],
            correct_count=session["correct_count"],
            confusion_count=session["confusion_count"],
            rounds_completed=session["rounds_completed"],
            is_complete=session.get("is_complete", False),
            score=round(score, 1),
        )

    # ── Private helpers ──────────────────────────────────────────────────────

    def _generate_objects(self, count: int, obj_key: str) -> list:
        """Generate a list of ObjectItem for display."""
        pool = OBJECT_POOLS[obj_key]
        return [
            ObjectItem(emoji=pool["emoji"], object_type=pool["type"])
            for _ in range(count)
        ]

    def _pixy_guess_count(self, target: int, model_level: str) -> int:
        """Pixy makes a guess based on model level."""
        if model_level == "junior":
            # 40% correct
            if random.random() < 0.40:
                return target
            else:
                wrong = [n for n in range(1, 6) if n != target]
                return random.choice(wrong)
        elif model_level == "student":
            # 70% correct
            if random.random() < 0.70:
                return target
            else:
                wrong = [n for n in range(1, 6) if n != target]
                return random.choice(wrong)
        else:  # expert
            # 95% correct
            if random.random() < 0.95:
                return target
            else:
                wrong = [n for n in range(1, 6) if n != target]
                return random.choice(wrong)

    def _complete_mission(self, user_id: int, session: dict):
        """Mark the mission as complete in the database."""
        session["is_complete"] = True
        try:
            mission = self.mission_repo.db.query(Mission).filter(
                Mission.mission_path == "numbers"
            ).first()
            if mission:
                total_rounds = max(session["rounds_completed"], 1)
                score = (session["total_correct"] / total_rounds) * 100

                existing = self.mission_repo.get_progress_by_mission(user_id, mission.id)
                if existing:
                    if not existing.is_completed:
                        existing.is_completed = True
                        existing.completed_at = datetime.now(timezone.utc)
                        existing.score = score
                        self.mission_repo.db.commit()
                else:
                    new_progress = MissionProgress(
                        user_id=user_id,
                        mission_id=mission.id,
                        is_completed=True,
                        completed_at=datetime.now(timezone.utc),
                        score=score,
                    )
                    self.mission_repo.db.add(new_progress)
                    self.mission_repo.db.commit()
        except Exception as e:
            print(f"[ERROR] Failed to save mission progress: {e}")
