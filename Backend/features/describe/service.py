import os
import re
import random
import tempfile
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dotenv import load_dotenv

from .schemas import (
    DescribeImageInfo,
    DescribeStartResponse,
    TranscriptionResponse,
    DescribeProgressResponse,
)

load_dotenv()


class DescribeMissionService:
    """
    Service for the Describe Mission — "Describe what you see in the image."
    
    Handles:
    - Image selection with expected keywords
    - Audio transcription via OpenAI Whisper API
    - Keyword-based validation
    - Performance logging
    """
    
    # ═══════════════════════════════════════════════════════════════════════
    # IMAGE BANK: (image_id, filename, expected_keywords, hint)
    # ═══════════════════════════════════════════════════════════════════════
    
    IMAGE_BANK = [
        ("dog_park", "dog_park.png",
         ["dog", "brown", "park", "grass", "running"],
         "What animal do you see? What is it doing?"),
        
        ("cat_sofa", "cat_sofa.png",
         ["cat", "orange", "sofa", "sleeping", "couch"],
         "What animal is on the sofa?"),
        
        ("red_car", "red_car.png",
         ["car", "red", "road", "driving", "street"],
         "What vehicle do you see? What color is it?"),
        
        ("apple_table", "apple_table.png",
         ["apple", "red", "table", "fruit", "wooden"],
         "What fruit do you see? Where is it?"),
        
        ("bird_tree", "bird_tree.png",
         ["bird", "blue", "tree", "branch", "singing"],
         "What's sitting on the tree?"),
        
        ("fish_water", "fish_water.png",
         ["fish", "orange", "water", "swimming", "bowl"],
         "What's in the water?"),
        
        ("house_garden", "house_garden.png",
         ["house", "white", "garden", "flowers", "fence"],
         "What building do you see?"),
        
        ("ball_playground", "ball_playground.png",
         ["ball", "colorful", "playground", "ground", "round"],
         "What toy do you see? Where is it?"),
    ]
    
    DATASET_PATH = Path(__file__).parent.parent.parent / "Resources" / "Describe Dataset"
    ROUNDS_PER_MISSION = 5
    
    def __init__(self):
        self._session: Dict = {}
        self._openai_client = None
        self._reset_session()
        self._init_openai()
    
    def _init_openai(self):
        """Initialize the OpenAI client if API key is available."""
        api_key = os.getenv("OPENAI_API_KEY", "")
        if api_key and api_key != "your-openai-api-key-here":
            try:
                from openai import OpenAI
                self._openai_client = OpenAI(api_key=api_key)
                print("[OK] OpenAI client initialized for Whisper API")
            except ImportError:
                print("[WARN] openai package not installed. Run: pip install openai")
                self._openai_client = None
            except Exception as e:
                print(f"[WARN] Failed to initialize OpenAI client: {e}")
                self._openai_client = None
        else:
            print("[WARN] OPENAI_API_KEY not set. Whisper transcription will use mock mode.")
            self._openai_client = None
    
    def _reset_session(self):
        """Reset mission session state."""
        self._session = {
            "current_round": 0,
            "total_rounds": self.ROUNDS_PER_MISSION,
            "used_images": [],
            "round_results": [],
            "total_score": 0.0,
        }
    
    def start_mission(self) -> DescribeStartResponse:
        """Start a new describe mission — pick an image."""
        self._reset_session()
        return self._get_next_image()
    
    def get_next_round(self) -> DescribeStartResponse:
        """Get the next image for description."""
        self._session["current_round"] += 1
        return self._get_next_image()
    
    def _get_next_image(self) -> DescribeStartResponse:
        """Pick a random unused image."""
        used = self._session["used_images"]
        available = [img for img in self.IMAGE_BANK if img[0] not in used]
        
        if not available:
            # All used — reset but avoid immediate repeats
            available = self.IMAGE_BANK
        
        image_data = random.choice(available)
        image_id, filename, keywords, hint = image_data
        
        self._session["used_images"].append(image_id)
        self._session["current_image"] = image_data
        
        return DescribeStartResponse(
            missionId=2,
            image=DescribeImageInfo(
                imageId=image_id,
                imageUrl=f"/describe/image/{filename}",
                expectedKeywords=keywords,
                hint=hint,
            ),
            instruction="Press record and describe what you see in the image.",
            round=self._session["current_round"] + 1,
            totalRounds=self._session["total_rounds"],
        )
    
    async def transcribe_audio(self, audio_bytes: bytes, filename: str) -> str:
        """
        Transcribe audio using OpenAI Whisper API.
        Falls back to mock transcription if API is unavailable.
        """
        if self._openai_client:
            return await self._whisper_transcribe(audio_bytes, filename)
        else:
            return self._mock_transcribe()
    
    async def _whisper_transcribe(self, audio_bytes: bytes, filename: str) -> str:
        """Call the OpenAI Whisper API for transcription."""
        try:
            # Write to temp file (Whisper API needs a file-like object)
            suffix = Path(filename).suffix or ".wav"
            with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
                tmp.write(audio_bytes)
                tmp_path = tmp.name
            
            with open(tmp_path, "rb") as audio_file:
                response = self._openai_client.audio.transcriptions.create(
                    model="gpt-4o-mini-transcribe",
                    file=audio_file,
                )
            
            # Clean up temp file
            os.unlink(tmp_path)
            
            return response.text.strip()
            
        except Exception as e:
            print(f"[ERROR] Whisper transcription failed: {e}")
            # Fallback to mock on error
            return self._mock_transcribe()
    
    def _mock_transcribe(self) -> str:
        """
        Mock transcription for testing without API key.
        Returns a plausible sentence using some keywords from the current image.
        """
        current = self._session.get("current_image")
        if not current:
            return "I see something interesting in the image."
        
        _, _, keywords, _ = current
        # Pick 2-3 random keywords to simulate partial recognition
        picked = random.sample(keywords, min(random.randint(2, 3), len(keywords)))
        templates = [
            f"I see a {picked[0]} that is {picked[1] if len(picked) > 1 else 'there'}",
            f"There is a {picked[0]} in the picture",
            f"I can see a {picked[0]} and it looks {picked[1] if len(picked) > 1 else 'nice'}",
        ]
        return random.choice(templates)
    
    def validate_transcription(self, transcription: str) -> TranscriptionResponse:
        """
        Validate transcription against expected keywords.
        
        Steps:
        1. Normalize text (lowercase, remove punctuation)
        2. Compare with expected keywords
        3. Compute match score
        4. Generate feedback
        """
        current = self._session.get("current_image")
        if not current:
            return TranscriptionResponse(
                success=False,
                transcription=transcription,
                matchScore=0.0,
                matchedKeywords=[],
                missingKeywords=[],
                message="No active image. Start a new round first.",
                encouragement="",
            )
        
        _, _, expected_keywords, _ = current
        
        # Normalize transcription
        normalized = self._normalize_text(transcription)
        
        # Match keywords
        matched = []
        missing = []
        for keyword in expected_keywords:
            if keyword.lower() in normalized:
                matched.append(keyword)
            else:
                missing.append(keyword)
        
        # Compute score
        match_score = len(matched) / max(len(expected_keywords), 1)
        
        # Save result
        result = {
            "round": self._session["current_round"] + 1,
            "image_id": current[0],
            "transcription": transcription,
            "matchScore": round(match_score, 2),
            "matchedKeywords": matched,
            "missingKeywords": missing,
        }
        self._session["round_results"].append(result)
        self._session["total_score"] += match_score
        
        # Generate feedback
        message, encouragement = self._generate_feedback(match_score, matched, missing)
        
        # Log
        self._log_performance(current[0], transcription, match_score)
        
        return TranscriptionResponse(
            success=True,
            transcription=transcription,
            matchScore=round(match_score, 2),
            matchedKeywords=matched,
            missingKeywords=missing,
            message=message,
            encouragement=encouragement,
        )
    
    def get_progress(self) -> DescribeProgressResponse:
        """Get current session progress."""
        results = self._session.get("round_results", [])
        completed = len(results)
        total = self._session.get("total_rounds", self.ROUNDS_PER_MISSION)
        avg_score = (self._session["total_score"] / max(completed, 1))
        
        return DescribeProgressResponse(
            completed=completed,
            total=total,
            totalScore=round(avg_score, 2),
            roundResults=results,
        )
    
    def _normalize_text(self, text: str) -> str:
        """Normalize text: lowercase, remove punctuation."""
        text = text.lower()
        text = re.sub(r'[^\w\s]', '', text)
        return text
    
    def _generate_feedback(
        self, score: float, matched: List[str], missing: List[str]
    ) -> Tuple[str, str]:
        """Generate user-faced feedback + mascot encouragement."""
        if score >= 0.8:
            messages = [
                ("Excellent description! You noticed so many details! 🌟", "Pixy is amazed! 🤩"),
                ("Wonderful! You really know how to describe things! ✨", "You're a description master! 🏆"),
            ]
        elif score >= 0.5:
            messages = [
                (f"Good try! You got {len(matched)} keywords. Can you spot more details?", 
                 "You're getting better! 💪"),
                (f"Nice! You noticed: {', '.join(matched)}. Look for more!", 
                 "Keep looking carefully! 👀"),
            ]
        else:
            messages = [
                ("Let's try to look more carefully at the image. What do you see?", 
                 "Don't worry, practice makes perfect! 🌈"),
                ("Try describing the colors, shapes, and objects you can see!", 
                 "Pixy believes in you! 🤗"),
            ]
        
        return random.choice(messages)
    
    def _log_performance(self, image_id: str, transcription: str, score: float):
        """
        Log performance for analytics.
        
        In production, would persist to database:
        - User ID, Mission ID, Image ID
        - Transcription text, Match score
        - Time spent, Difficulty level
        """
        status = "★" if score >= 0.8 else "●" if score >= 0.5 else "○"
        print(f"[DESCRIBE] {status} image={image_id} score={score:.0%} → '{transcription[:50]}'")
    
    def get_image_path(self, filename: str) -> Path:
        """Get file path for a describe image."""
        return self.DATASET_PATH / filename


# ═══════════════════════════════════════════════════════════════════════
# Singleton
# ═══════════════════════════════════════════════════════════════════════

_service_instance = None

def get_describe_service() -> DescribeMissionService:
    """Get or create the describe service singleton."""
    global _service_instance
    if _service_instance is None:
        _service_instance = DescribeMissionService()
    return _service_instance
