"""
Describe Mission Service — "Describe what you see" (bilingual, emoji-based).

The mission shows a single friendly emoji scene per round. The child presses
Record, describes the scene out loud in English or Romanian, and the backend:

1. Transcribes audio via OpenAI Whisper (gpt-4o-mini-transcribe).
2. Normalises and matches the transcription against EN and RO keyword banks.
3. Picks the best-scoring language, returns matched/missing keywords,
   plus a short feedback + encouragement line.

Five rounds are pre-generated at /start so the client can flip between them
locally without extra round-trips; the server only validates transcriptions.
"""

from __future__ import annotations

import os
import re
import random
import tempfile
import unicodedata
from pathlib import Path
from typing import List, Dict, Tuple, Optional

from dotenv import load_dotenv

from .schemas import (
    DescribeItem,
    DescribeStartResponse,
    DescribeAnswerResponse,
    DescribeProgressResponse,
    TranscriptionRoundResult,
)

load_dotenv()


# ═════════════════════════════════════════════════════════════════════════════
# SCENE BANK — 10 kid-friendly emoji scenes, each with EN + RO keywords
# Keywords include color/animal/action/location variants, so many correct
# descriptions are accepted.
# ═════════════════════════════════════════════════════════════════════════════

SCENE_BANK: List[DescribeItem] = [
    DescribeItem(
        id=1,
        emoji="🐕",
        secondaryEmoji="🌳",
        accentHex="#FFB547",
        themeEn="Animal",
        themeRo="Animal",
        hintEn="What animal do you see? Where is it?",
        hintRo="Ce animal vezi? Unde este?",
        keywordsEn=["dog", "puppy", "brown", "park", "tree"],
        keywordsRo=["câine", "cățel", "maro", "parc", "copac"],
    ),
    DescribeItem(
        id=2,
        emoji="🐱",
        secondaryEmoji="🛋️",
        accentHex="#FF8A65",
        themeEn="Animal",
        themeRo="Animal",
        hintEn="Which pet is relaxing on the sofa?",
        hintRo="Ce animăluț se odihnește pe canapea?",
        keywordsEn=["cat", "kitten", "orange", "sofa", "sleeping"],
        keywordsRo=["pisică", "pisicuță", "portocalie", "canapea", "doarme"],
    ),
    DescribeItem(
        id=3,
        emoji="🍎",
        secondaryEmoji="🧺",
        accentHex="#EF5350",
        themeEn="Fruit",
        themeRo="Fruct",
        hintEn="What fruit do you see? What color is it?",
        hintRo="Ce fruct vezi? Ce culoare are?",
        keywordsEn=["apple", "red", "fruit", "basket", "round"],
        keywordsRo=["măr", "roșu", "fruct", "coș", "rotund"],
    ),
    DescribeItem(
        id=4,
        emoji="🚗",
        secondaryEmoji="🛣️",
        accentHex="#42A5F5",
        themeEn="Vehicle",
        themeRo="Vehicul",
        hintEn="What vehicle do you see? What is it doing?",
        hintRo="Ce vehicul vezi? Ce face?",
        keywordsEn=["car", "red", "road", "driving", "street"],
        keywordsRo=["mașină", "roșie", "drum", "merge", "stradă"],
    ),
    DescribeItem(
        id=5,
        emoji="🐦",
        secondaryEmoji="🌿",
        accentHex="#26A69A",
        themeEn="Bird",
        themeRo="Pasăre",
        hintEn="What is sitting on the branch?",
        hintRo="Ce stă pe crenguță?",
        keywordsEn=["bird", "blue", "tree", "branch", "singing"],
        keywordsRo=["pasăre", "albastră", "copac", "creangă", "cântă"],
    ),
    DescribeItem(
        id=6,
        emoji="🐟",
        secondaryEmoji="💧",
        accentHex="#29B6F6",
        themeEn="Animal",
        themeRo="Animal",
        hintEn="What swims in the water?",
        hintRo="Ce înoată în apă?",
        keywordsEn=["fish", "orange", "water", "swimming", "small"],
        keywordsRo=["pește", "portocaliu", "apă", "înoată", "mic"],
    ),
    DescribeItem(
        id=7,
        emoji="🏠",
        secondaryEmoji="🌼",
        accentHex="#AB47BC",
        themeEn="Building",
        themeRo="Clădire",
        hintEn="What building do you see? What is around it?",
        hintRo="Ce clădire vezi? Ce este în jurul ei?",
        keywordsEn=["house", "roof", "garden", "flower", "home"],
        keywordsRo=["casă", "acoperiș", "grădină", "floare", "cămin"],
    ),
    DescribeItem(
        id=8,
        emoji="⚽",
        secondaryEmoji="🌱",
        accentHex="#66BB6A",
        themeEn="Toy",
        themeRo="Jucărie",
        hintEn="What toy do you see? Where is it?",
        hintRo="Ce jucărie vezi? Unde este?",
        keywordsEn=["ball", "round", "grass", "soccer", "white"],
        keywordsRo=["minge", "rotundă", "iarbă", "fotbal", "albă"],
    ),
    DescribeItem(
        id=9,
        emoji="🦋",
        secondaryEmoji="🌸",
        accentHex="#EC407A",
        themeEn="Insect",
        themeRo="Insectă",
        hintEn="What flies near the flower?",
        hintRo="Ce zboară lângă floare?",
        keywordsEn=["butterfly", "flower", "wings", "pink", "flying"],
        keywordsRo=["fluture", "floare", "aripi", "roz", "zboară"],
    ),
    DescribeItem(
        id=10,
        emoji="🌞",
        secondaryEmoji="☁️",
        accentHex="#FFCA28",
        themeEn="Weather",
        themeRo="Vreme",
        hintEn="What do you see in the sky?",
        hintRo="Ce vezi pe cer?",
        keywordsEn=["sun", "yellow", "sky", "cloud", "bright"],
        keywordsRo=["soare", "galben", "cer", "nor", "strălucitor"],
    ),
]


ROUNDS_PER_MISSION = 5


# ═════════════════════════════════════════════════════════════════════════════
# TEXT NORMALISATION — strip diacritics + punctuation, lowercase
# ═════════════════════════════════════════════════════════════════════════════

def _strip_diacritics(text: str) -> str:
    """Normalize Romanian diacritics (ă, â, î, ș, ț) for keyword matching."""
    nfkd = unicodedata.normalize("NFKD", text)
    return "".join(c for c in nfkd if not unicodedata.combining(c))


def _normalise(text: str) -> str:
    text = text.lower()
    text = _strip_diacritics(text)
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _score_against(transcription_norm: str, keywords: List[str]) -> Tuple[List[str], List[str]]:
    """Return (matched, missing) for a given keyword bank."""
    matched: List[str] = []
    missing: List[str] = []
    for kw in keywords:
        kw_norm = _normalise(kw)
        # Word-boundary-ish match so "cat" doesn't match "scatter".
        if re.search(rf"\b{re.escape(kw_norm)}", transcription_norm):
            matched.append(kw)
        else:
            missing.append(kw)
    return matched, missing


# ═════════════════════════════════════════════════════════════════════════════
# SERVICE
# ═════════════════════════════════════════════════════════════════════════════

class DescribeMissionService:
    """Holds the current mission session plus the Whisper client."""

    def __init__(self):
        self._session: Dict = {}
        self._openai_client = None
        self._reset_session()
        self._init_openai()

    # ─── OpenAI (Whisper) lifecycle ──────────────────────────────────────

    def _init_openai(self) -> None:
        api_key = os.getenv("OPENAI_API_KEY", "")
        if api_key and api_key != "your-openai-api-key-here":
            try:
                from openai import OpenAI
                self._openai_client = OpenAI(api_key=api_key)
                print("[OK] OpenAI client initialised for Whisper API")
            except ImportError:
                print("[WARN] openai package not installed. Run: pip install openai")
            except Exception as e:
                print(f"[WARN] OpenAI init failed: {e}")
        else:
            print("[WARN] OPENAI_API_KEY not set — Describe mission will use mock transcription.")

    # ─── Session management ──────────────────────────────────────────────

    def _reset_session(self) -> None:
        # Pick ROUNDS_PER_MISSION unique scenes in random order.
        rounds = random.sample(SCENE_BANK, min(ROUNDS_PER_MISSION, len(SCENE_BANK)))
        self._session = {
            "questions": rounds,
            "round_results": [],
            "total_score": 0.0,
        }

    def start_mission(self) -> DescribeStartResponse:
        self._reset_session()
        return DescribeStartResponse(
            missionId=-8,
            questions=list(self._session["questions"]),
            totalRounds=len(self._session["questions"]),
        )

    def get_progress(self) -> DescribeProgressResponse:
        results = self._session.get("round_results", [])
        total = len(self._session.get("questions", [])) or ROUNDS_PER_MISSION
        completed = len(results)
        correct = sum(1 for r in results if r.get("correct"))
        accuracy = (correct / completed) if completed else 0.0
        avg_score = (self._session["total_score"] / completed) if completed else 0.0
        return DescribeProgressResponse(
            completed=completed,
            total=total,
            correctCount=correct,
            accuracy=round(accuracy, 2),
            averageScore=round(avg_score, 2),
        )

    # ─── Whisper ─────────────────────────────────────────────────────────

    async def transcribe_audio(self, audio_bytes: bytes, filename: str) -> str:
        if self._openai_client:
            try:
                return await self._whisper_transcribe(audio_bytes, filename)
            except Exception as e:
                print(f"[ERROR] Whisper transcription failed: {e}")
                return self._mock_transcribe()
        return self._mock_transcribe()

    async def _whisper_transcribe(self, audio_bytes: bytes, filename: str) -> str:
        suffix = Path(filename).suffix or ".wav"
        tmp_path: Optional[str] = None
        try:
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
                tmp.write(audio_bytes)
                tmp_path = tmp.name
            with open(tmp_path, "rb") as audio_file:
                response = self._openai_client.audio.transcriptions.create(
                    model="gpt-4o-mini-transcribe",
                    file=audio_file,
                )
            return (response.text or "").strip()
        finally:
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.unlink(tmp_path)
                except OSError:
                    pass

    def _mock_transcribe(self, question_index: Optional[int] = None) -> str:
        """Fallback when the API is unavailable — fakes a plausible description."""
        questions = self._session.get("questions", [])
        if not questions:
            return "I see something nice in the picture."
        if question_index is None or question_index < 0 or question_index >= len(questions):
            item = random.choice(questions)
        else:
            item = questions[question_index]
        # Pick 2-3 English keywords to simulate partial recognition.
        picks = random.sample(item.keywordsEn, min(3, len(item.keywordsEn)))
        return f"I see a {picks[0]} and it is {picks[1] if len(picks) > 1 else 'nice'}."

    # ─── Round validation ────────────────────────────────────────────────

    def validate_round(
        self,
        question_index: int,
        transcription: str,
    ) -> DescribeAnswerResponse:
        questions: List[DescribeItem] = self._session.get("questions", [])
        if not questions:
            return self._no_session_result(transcription)

        if question_index < 0 or question_index >= len(questions):
            return self._no_session_result(transcription)

        item = questions[question_index]
        norm = _normalise(transcription)

        matched_en, missing_en = _score_against(norm, item.keywordsEn)
        matched_ro, missing_ro = _score_against(norm, item.keywordsRo)

        score_en = len(matched_en) / max(len(item.keywordsEn), 1)
        score_ro = len(matched_ro) / max(len(item.keywordsRo), 1)

        if score_ro > score_en:
            detected_lang = "ro"
            matched, missing = matched_ro, missing_ro
            best = score_ro
        elif score_en > 0:
            detected_lang = "en"
            matched, missing = matched_en, missing_en
            best = score_en
        elif score_ro > 0:
            detected_lang = "ro"
            matched, missing = matched_ro, missing_ro
            best = score_ro
        else:
            # Both zero — default to English and show EN hint keywords.
            detected_lang = "en"
            matched, missing = matched_en, missing_en
            best = 0.0

        correct = best >= 0.4  # at least 2/5 keywords considered a pass
        message, encouragement = self._feedback(best, detected_lang)

        # Save state
        self._session["round_results"].append({
            "index": question_index,
            "score": round(best, 2),
            "correct": correct,
            "transcription": transcription,
        })
        self._session["total_score"] += best

        result = TranscriptionRoundResult(
            success=True,
            transcription=transcription,
            detectedLang=detected_lang,
            matchScore=round(best, 2),
            matchedKeywords=matched,
            missingKeywords=missing,
            message=message,
            encouragement=encouragement,
        )

        self._log(item.id, transcription, best)

        return DescribeAnswerResponse(
            success=True,
            correct=correct,
            result=result,
            completed=len(self._session["round_results"]),
            total=len(questions),
        )

    def _no_session_result(self, transcription: str) -> DescribeAnswerResponse:
        empty = TranscriptionRoundResult(
            success=False,
            transcription=transcription,
            detectedLang="en",
            matchScore=0.0,
            matchedKeywords=[],
            missingKeywords=[],
            message="No active round. Please start the mission first.",
            encouragement="",
        )
        return DescribeAnswerResponse(
            success=False,
            correct=False,
            result=empty,
            completed=0,
            total=0,
        )

    # ─── Feedback ────────────────────────────────────────────────────────

    @staticmethod
    def _feedback(score: float, detected_lang: str) -> Tuple[str, str]:
        """Return (message, encouragement). Keep it short — UI also localises."""
        if score >= 0.8:
            return (
                "Wonderful! You spotted so many details.",
                "Pixy is amazed!",
            )
        if score >= 0.5:
            return (
                "Nice — you caught a few key details.",
                "Look for one or two more next time.",
            )
        if score >= 0.2:
            return (
                "Good try! Can you describe more of what you see?",
                "Talk about colors, shapes, what it's doing.",
            )
        return (
            "Let's look again and try to describe what is in the picture.",
            "Practice makes perfect — Pixy believes in you!",
        )

    @staticmethod
    def _log(scene_id: int, transcription: str, score: float) -> None:
        badge = "★" if score >= 0.8 else "●" if score >= 0.5 else "○"
        print(f"[DESCRIBE] {badge} scene={scene_id} score={score:.0%} → '{transcription[:60]}'")


# ═════════════════════════════════════════════════════════════════════════════
# Singleton accessor
# ═════════════════════════════════════════════════════════════════════════════

_service_instance: Optional[DescribeMissionService] = None


def get_describe_service() -> DescribeMissionService:
    global _service_instance
    if _service_instance is None:
        _service_instance = DescribeMissionService()
    return _service_instance
