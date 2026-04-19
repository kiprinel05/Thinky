import random
from typing import Dict, Optional
from datetime import datetime, timezone

from features.numbers.schemas import (
    ObjectItem, NumbersStartResponse, NumbersRoundResponse,
    CountingSubmission, CountingResponse,
    DrawingResponse, NumbersProgressResponse,
    TeachDrawingSubmission, TeachDrawingResponse,
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

# Pixy personality messages per model level — bilingual (EN / RO)
PIXY_MESSAGES = {
    "ro": {
        "junior": {
            "guess": "Hmm… cred că sunt {n}? 🤔",
            "correct_confirmed": "Ura! Am ghicit! Mulțumesc că m-ai ajutat! 😊",
            "wrong_confirmed": "Oh, ok… atunci sunt {n}... 😕",
            "corrected": "Ohhh, am greșit? Atunci sunt {n}! Mulțumesc! 😅",
            "confused": "Sunt confuz... nu mai știu câte sunt... 😵",
            "drawing_thinks": "Hmm… cred că ai desenat un {n}? 🤔",
            "drawing_confirmed": "Yey! Am ghicit! Era un {n}! 😊",
            "drawing_corrected": "Aha, era un {n}? Mulțumesc, învăț! 😅",
            "drawing_caught_lying": "Sigur era un {n}? Eu eram destul de sigur că este un {m}... 🤨",
        },
        "student": {
            "guess": "Cred că sunt {n}! 🙂",
            "correct_confirmed": "Super! Am ghicit corect! Învăț repede! 😄",
            "wrong_confirmed": "Hmm, sigur sunt {n}? Ok... 🤨",
            "corrected": "Aha, sunt {n}! Am înțeles, mulțumesc! 📝",
            "confused": "Hmm, sunt puțin confuz acum... 😕",
            "drawing_thinks": "Cred că ai desenat un {n}! 🙂",
            "drawing_confirmed": "Excelent! Era un {n}! Recunosc tot mai bine! 😄",
            "drawing_corrected": "Aha, era un {n}! Am notat, mulțumesc! 📝",
            "drawing_caught_lying": "Hmm, dar mie chiar mi se părea un {m}... ești sigur că este {n}? 🤔",
        },
        "expert": {
            "guess": "Este clar! Sunt {n}! 🎉",
            "correct_confirmed": "Știam! Am învățat foarte bine! 🌟",
            "wrong_confirmed": "Hmm, chiar sunt {n}? Mă gândesc din nou... 🧐",
            "corrected": "Oh, am greșit! Sunt {n}. Mulțumesc pentru corecție! 🙏",
            "confused": "Ciudat, ceva nu se potrivește... 😐",
            "drawing_thinks": "Este clar! Ai desenat numărul {n}! 🎉",
            "drawing_confirmed": "Perfect! Era un {n}! Acum recunosc cifrele foarte bine! 🌟",
            "drawing_corrected": "Oh, era un {n}? Mulțumesc, mă antrenez mai mult! 🙏",
            "drawing_caught_lying": "Eram foarte sigur că este un {m}, nu un {n}... ești absolut sigur? 🧐",
        },
    },
    "en": {
        "junior": {
            "guess": "Hmm… I think there are {n}? 🤔",
            "correct_confirmed": "Yay! I guessed it! Thanks for helping me! 😊",
            "wrong_confirmed": "Oh, okay… so it's {n}... 😕",
            "corrected": "Ohhh, I was wrong? So it's {n}! Thank you! 😅",
            "confused": "I'm confused... I don't know how many there are anymore... 😵",
            "drawing_thinks": "Hmm… I think you drew a {n}? 🤔",
            "drawing_confirmed": "Yay! I guessed right! It was a {n}! 😊",
            "drawing_corrected": "Oh, it was a {n}? Thanks, I'm learning! 😅",
            "drawing_caught_lying": "Are you sure it was a {n}? I was pretty sure it looked like a {m}... 🤨",
        },
        "student": {
            "guess": "I think there are {n}! 🙂",
            "correct_confirmed": "Awesome! I guessed right! I'm learning fast! 😄",
            "wrong_confirmed": "Hmm, are you sure it's {n}? Ok... 🤨",
            "corrected": "Aha, it's {n}! Got it, thanks! 📝",
            "confused": "Hmm, I'm a little confused now... 😕",
            "drawing_thinks": "I think you drew a {n}! 🙂",
            "drawing_confirmed": "Awesome! It was a {n}! I'm getting better and better! 😄",
            "drawing_corrected": "Aha, it was a {n}! Noted, thanks! 📝",
            "drawing_caught_lying": "Hmm, but it really looked like a {m} to me... are you sure it's a {n}? 🤔",
        },
        "expert": {
            "guess": "It's clear! There are {n}! 🎉",
            "correct_confirmed": "I knew it! I've learned really well! 🌟",
            "wrong_confirmed": "Hmm, is it really {n}? Let me think again... 🧐",
            "corrected": "Oh, I was wrong! It's {n}. Thanks for the correction! 🙏",
            "confused": "Strange, something doesn't add up... 😐",
            "drawing_thinks": "Crystal clear! You drew the digit {n}! 🎉",
            "drawing_confirmed": "Perfect! It was a {n}! I recognize digits really well now! 🌟",
            "drawing_corrected": "Oh, it was a {n}? Thanks, I'll train more! 🙏",
            "drawing_caught_lying": "I was really confident it was a {m}, not a {n}... are you absolutely sure? 🧐",
        },
    },
}

PROFESSOR_MESSAGES = {
    "ro": {
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
        "wrong_teaching": (
            "Atenție! Pixy a recunoscut clar un {m}, dar tu i-ai spus că este un {n}. "
            "Dacă îl învățăm cifre greșite, AI-ul învață greșit. "
            "Spune-i mereu ce ai desenat cu adevărat — așa învață corect!"
        ),
        "model_upgrade": (
            "Bravo! Pixy a învățat suficient și a trecut la nivelul următor! "
            "AI-ul învață bine atunci când oamenii sunt atenți și răbdători. 🌟"
        ),
    },
    "en": {
        "wrong_count": (
            "Pixy learns from what we teach him. "
            "If we show him wrong things, he'll learn the wrong way. "
            "Let's help him out! Count the objects carefully."
        ),
        "wrong_drawing": (
            "Pixy doesn't know what's right or wrong. "
            "He learns from your drawings. "
            "If we teach him wrong, he'll recognize things wrong."
        ),
        "wrong_teaching": (
            "Careful! Pixy clearly recognized a {m}, but you told him it was a {n}. "
            "If we teach the AI wrong digits, it will learn wrong. "
            "Always tell Pixy what you really drew — that's how he learns properly!"
        ),
        "model_upgrade": (
            "Great job! Pixy has learned enough and moved to the next level! "
            "AI learns best when people are attentive and patient. 🌟"
        ),
    },
}

START_MESSAGES = {
    "ro": "Bună! Eu sunt Pixy! Ajută-mă să învăț câte obiecte sunt! 🤖",
    "en": "Hi! I'm Pixy! Help me learn how many objects there are! 🤖",
}


def _normalize_lang(lang: Optional[str]) -> str:
    """Normalize an Accept-Language style string to one of our supported codes."""
    if not lang:
        return "en"
    # Take the first 2 chars (handles "en-US", "ro-RO", "en, ro;q=0.9", etc.)
    code = lang.strip().lower()[:2]
    return code if code in ("en", "ro") else "en"


def _pixy_msgs(model_level: str, lang: str) -> Dict[str, str]:
    return PIXY_MESSAGES.get(lang, PIXY_MESSAGES["en"])[model_level]


def _professor_msgs(lang: str) -> Dict[str, str]:
    return PROFESSOR_MESSAGES.get(lang, PROFESSOR_MESSAGES["en"])

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
                # Drawing-specific (Part 2): free-draw / teach loop
                "last_recognized_digit": None,
                "last_raw_confidence": 0.0,
                "examples_taught": 0,
                "drawing_lying_count": 0,
            }
        return self._sessions[user_id]

    def start_session(self, user_id: int, lang: str = "en") -> NumbersStartResponse:
        """Start a new numbers learning session."""
        lang = _normalize_lang(lang)
        session = self._get_or_create_session(user_id)

        # Reset session
        session["correct_count"] = 0
        session["confusion_count"] = 0
        session["model_level"] = "junior"
        session["current_part"] = 1
        session["rounds_completed"] = 0
        session["total_correct"] = 0
        session["last_recognized_digit"] = None
        session["last_raw_confidence"] = 0.0
        session["examples_taught"] = 0
        session["drawing_lying_count"] = 0

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
            message=START_MESSAGES.get(lang, START_MESSAGES["en"]),
        )

    def get_round(self, user_id: int, lang: str = "en") -> NumbersRoundResponse:
        """Get the current round data including Pixy's guess."""
        lang = _normalize_lang(lang)
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

        messages = _pixy_msgs(model_level, lang)
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

    def submit_count(self, user_id: int, submission: CountingSubmission, lang: str = "en") -> CountingResponse:
        """Process a counting answer from the child."""
        lang = _normalize_lang(lang)
        session = self._get_or_create_session(user_id)
        target = session["target_number"]
        model_level = session["model_level"]
        pixy_guess = session.get("pixy_guess", target)
        messages = _pixy_msgs(model_level, lang)
        prof_messages = _professor_msgs(lang)

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
                    professor_message = prof_messages["wrong_count"]
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
                    professor_message = prof_messages["wrong_count"]
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

    # ── Drawing flow (free-draw + teach) ─────────────────────────────────────
    #
    # The child draws any digit they like (0-9). Pixy makes a guess
    # (`submit_drawing`). The UI then asks the child to confirm or correct
    # the guess (`teach_drawing`). Pixy "learns" with each example: confidence
    # grows and reaches ~100% by the 4th–5th example. If the recognizer was
    # very confident in something different from what the child claimed, the
    # professor steps in to warn against teaching the AI wrong things.

    # Threshold above which the recognizer is considered "confident" about its
    # own answer; if the child claims something else, that's a probable lie.
    CHEATING_CONFIDENCE_THRESHOLD = 0.70

    @staticmethod
    def _display_confidence(raw: float, examples_taught: int) -> float:
        """Blend the raw recognizer confidence with a learning bonus.

        Reaches 100% by the 5th confirmed example, regardless of raw value, so
        the simulated AI feels like it actually gets better with each round.
        """
        floor = min(1.0, 0.30 + 0.18 * examples_taught)  # 0.30, 0.48, 0.66, 0.84, 1.00
        return float(min(1.0, max(raw, floor)))

    def submit_drawing(self, user_id: int, image_bytes: bytes, lang: str = "en") -> DrawingResponse:
        """Pixy looks at the drawing and proposes a guess.

        No `target` digit is involved — the child is free to draw any digit
        from 0 to 9. The UI must follow up with `teach_drawing` so the child
        can confirm / correct what they actually drew.
        """
        lang = _normalize_lang(lang)
        session = self._get_or_create_session(user_id)
        model_level = session["model_level"]
        messages = _pixy_msgs(model_level, lang)

        # Recognize the digit. The recognizer is built around 1–5; if it
        # returns 0, fall back to its best non-zero guess (still safe — we
        # only need a coherent display value).
        guessed_digit, raw_confidence = digit_recognition_service.recognize(
            image_bytes, model_level
        )
        if not guessed_digit:
            guessed_digit = random.randint(1, 5)
            raw_confidence = max(raw_confidence, 0.20)

        examples_taught = int(session.get("examples_taught", 0))
        display_conf = self._display_confidence(raw_confidence, examples_taught)

        session["last_recognized_digit"] = guessed_digit
        session["last_raw_confidence"] = float(raw_confidence)

        pixy_message = messages["drawing_thinks"].format(n=guessed_digit)

        return DrawingResponse(
            guessed_digit=guessed_digit,
            confidence=display_conf,
            pixy_message=pixy_message,
            pixy_emotion="thinking",
            model_level=model_level,
            examples_taught=examples_taught,
            awaiting_confirmation=True,
        )

    def teach_drawing(
        self,
        user_id: int,
        submission: TeachDrawingSubmission,
        lang: str = "en",
    ) -> TeachDrawingResponse:
        """The child confirms or corrects Pixy's last guess."""
        lang = _normalize_lang(lang)
        session = self._get_or_create_session(user_id)
        model_level = session["model_level"]
        messages = _pixy_msgs(model_level, lang)
        prof_messages = _professor_msgs(lang)

        recognized = session.get("last_recognized_digit")
        raw_conf = float(session.get("last_raw_confidence", 0.0))
        claimed = int(submission.claimed_digit)

        was_pixy_correct = recognized is not None and claimed == recognized
        is_lying = (
            recognized is not None
            and claimed != recognized
            and raw_conf >= self.CHEATING_CONFIDENCE_THRESHOLD
        )

        show_professor = False
        professor_message = None
        professor_hint = None
        pixy_emotion = "happy"

        if is_lying:
            # Don't reward, don't penalise the model knowledge — but warn the kid.
            session["drawing_lying_count"] = int(session.get("drawing_lying_count", 0)) + 1
            session["confusion_count"] = int(session.get("confusion_count", 0)) + 1
            pixy_message = messages["drawing_caught_lying"].format(n=claimed, m=recognized)
            pixy_emotion = "confused"
            show_professor = True
            professor_message = prof_messages["wrong_teaching"].format(
                n=claimed, m=recognized
            )
        elif was_pixy_correct:
            session["correct_count"] = int(session["correct_count"]) + 1
            session["total_correct"] = int(session["total_correct"]) + 1
            session["examples_taught"] = int(session.get("examples_taught", 0)) + 1
            session["confusion_count"] = 0
            pixy_message = messages["drawing_confirmed"].format(n=claimed)
            pixy_emotion = "happy"
        else:
            # Pixy was wrong, the child corrected → still a valid teaching example.
            session["examples_taught"] = int(session.get("examples_taught", 0)) + 1
            session["confusion_count"] = 0
            pixy_message = messages["drawing_corrected"].format(n=claimed)
            pixy_emotion = "thinking"

        # ── Model upgrade after enough confirmed-correct examples ───────────
        model_upgraded = False
        new_model_level = None
        if session["correct_count"] >= CORRECT_TO_UPGRADE:
            current_idx = MODEL_LEVELS.index(model_level)
            if current_idx < len(MODEL_LEVELS) - 1:
                new_level = MODEL_LEVELS[current_idx + 1]
                session["model_level"] = new_level
                session["correct_count"] = 0
                model_upgraded = True
                new_model_level = new_level

        session["rounds_completed"] = int(session.get("rounds_completed", 0)) + 1

        # ── Part 2 completion ───────────────────────────────────────────────
        part_completed = False
        if (
            session["model_level"] == "expert"
            and session["correct_count"] >= CORRECT_TO_UPGRADE
        ):
            part_completed = True
            self._complete_mission(user_id, session)

        # Reset last-drawing state so the next round starts fresh.
        session["last_recognized_digit"] = None
        session["last_raw_confidence"] = 0.0

        return TeachDrawingResponse(
            was_pixy_correct=was_pixy_correct,
            is_lying=is_lying,
            claimed_digit=claimed,
            recognized_digit=recognized,
            pixy_message=pixy_message,
            pixy_emotion=pixy_emotion,
            model_level=session["model_level"],
            correct_count=session["correct_count"],
            confusion_count=session["confusion_count"],
            examples_taught=int(session.get("examples_taught", 0)),
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
