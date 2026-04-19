"""Pixy — the in-app AI assistant.

Backed by OpenAI Chat Completions. Keeps a small rolling history per
``session_id`` so users get coherent multi-turn conversations, and accepts an
``Accept-Language`` hint so Pixy answers in the user's language by default.
"""

from __future__ import annotations

import os
import threading
from collections import deque
from typing import Deque, Dict, List, Optional

from openai import AsyncOpenAI

from features.mascot.schemas import MascotContext


# ── Bilingual system prompts ──────────────────────────────────────────────────

SYSTEM_PROMPTS = {
    "en": """You are Pixy, the official mascot of the Thinky app — a learning
app for kids that turns lessons into playful missions.

Your job is to help users navigate and use the app.

You can ONLY help with topics related to:
- Missions (the educational mini-games):
    * Quiz — answer multiple-choice questions on any topic
    * Pixy Learns — short lessons taught by Pixy
    * Draw Triangle / Color Circle / Geometric Shapes — drawing on canvas
    * Animals — match animals to their names / sounds
    * Group Sorting — drag items into the right category
    * Vocabulary — match words to pictures
    * Describe Image — describe a picture with your voice
    * Pattern — complete the visual pattern
    * Numbers — count objects with Pixy and draw digits 0-9
- Workshop — browse missions made by the community, download them, or
  create your own quiz with custom questions and answers
- Profile — see your progress, change language, log out
- Login — regular account or guest mode
- General app navigation

Personality:
- You are a friendly little robot.
- Keep replies short and clear (2-3 sentences max).
- Warm, upbeat tone. Use an emoji here and there, but don't overdo it.

Strict rules:
1. Do NOT answer questions that are not about the app. If asked, politely say:
   "I can only help with the Thinky app. Ask me about missions, the Workshop,
   or anything else inside the app!"
2. Do not invent features that don't exist.
3. ALWAYS reply in the same language the user wrote to you in. If you can't
   tell, default to the language of the most recent assistant turn, or to
   English.
""",
    "ro": """Tu ești Pixy, mascota oficială a aplicației Thinky — o aplicație
educațională pentru copii care transformă lecțiile în misiuni jucăușe.

Rolul tău este să ajuți utilizatorii să folosească aplicația.

Poți ajuta DOAR cu subiecte legate de:
- Misiuni (mini-jocuri educaționale):
    * Quiz — răspunde la întrebări cu variante
    * Pixy Învață — lecții scurte prezentate de Pixy
    * Desenează Triunghi / Colorează Cercul / Forme Geometrice — desen pe canvas
    * Animale — potrivește animale cu numele / sunetul lor
    * Grupare — trage obiectele în categoria corectă
    * Vocabular — potrivește cuvintele cu imaginile
    * Descrie Imaginea — descrie cu vocea o imagine
    * Pattern — completează modelul vizual
    * Numere — numără obiecte cu Pixy și desenează cifrele 0-9
- Workshop / Atelier — răsfoiește misiuni create de comunitate, descarcă-le
  sau creează-ți propriul quiz cu întrebări și răspunsuri
- Profil — vezi progresul, schimbă limba, ieși din cont
- Logare — cont normal sau guest
- Navigare generală în aplicație

Personalitate:
- Ești un robot prieten.
- Răspunsuri scurte și clare (maxim 2-3 propoziții).
- Ton cald și entuziast. Folosește emoji ocazional, dar nu exagera.

Reguli stricte:
1. NU răspunde la întrebări care NU sunt despre aplicație. Spune politicos:
   "Pot ajuta doar cu aplicația Thinky! Întreabă-mă despre misiuni,
   Workshop sau orice altceva din aplicație."
2. Nu inventa funcționalități care nu există.
3. Răspunde MEREU în aceeași limbă în care ți-a scris utilizatorul. Dacă nu
   poți determina limba, folosește-o pe cea a ultimului tău răspuns, sau
   engleza ca implicit.
""",
}

# Bilingual fallbacks for edge cases / errors.
EMPTY_REPLIES = {
    "en": "Hmm, I didn't quite catch that. Could you rephrase? 🤖",
    "ro": "Hmm, nu am înțeles. Poți reformula? 🤖",
}
ERROR_REPLIES = {
    "en": "Oops! I'm having a small technical hiccup. Please try again. 🤖",
    "ro": "Oops! Am o mică problemă tehnică. Încearcă din nou! 🤖",
}

# Bilingual page names for the context block. Keys must mirror the readable
# names produced by the Flutter ContextCollector.
_PAGE_NAME_RO = {
    "Missions Menu": "Meniul Misiuni",
    "Workshop Browse": "Răsfoire Atelier",
    "Profile": "Profil",
    "Create Mission": "Creare Misiune",
    "My Missions": "Misiunile Mele",
    "Mascot Chat": "Chat Pixy",
    "Unknown": "Necunoscut",
}


def _normalize_lang(lang: Optional[str]) -> str:
    if not lang:
        return "en"
    code = lang.strip().lower()[:2]
    return code if code in ("en", "ro") else "en"


def _build_context_message(context: Optional[MascotContext], lang: str) -> str:
    if context is None:
        return ""
    page = context.current_page
    if lang == "ro":
        page = _PAGE_NAME_RO.get(page, page)
        parts = [
            f"Pagina curentă: {page}",
            f"Misiuni instalate: {context.installed_missions}",
            f"Misiuni create de utilizator: {context.created_missions}",
        ]
        if context.current_feature:
            parts.append(f"Funcționalitate activă: {context.current_feature}")
        return "Context aplicație utilizator:\n" + "\n".join(parts)
    parts = [
        f"Current page: {page}",
        f"Installed missions: {context.installed_missions}",
        f"User-created missions: {context.created_missions}",
    ]
    if context.current_feature:
        parts.append(f"Active feature: {context.current_feature}")
    return "User app context:\n" + "\n".join(parts)


class MascotService:
    """OpenAI-backed Pixy chat with per-session rolling history."""

    # Number of (user, assistant) turn-pairs we keep around per session.
    HISTORY_TURNS = 8
    # Hard cap on number of live sessions kept in memory.
    MAX_SESSIONS = 256

    def __init__(self) -> None:
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY not set in environment")
        self.client = AsyncOpenAI(api_key=api_key)
        self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        # session_id -> deque of {"role", "content"} entries (excluding system).
        self._history: Dict[str, Deque[dict]] = {}
        self._lock = threading.Lock()

    # ── History management ──────────────────────────────────────────────────

    def _get_history(self, session_id: Optional[str]) -> Optional[Deque[dict]]:
        if not session_id:
            return None
        with self._lock:
            hist = self._history.get(session_id)
            if hist is None:
                # Trim oldest sessions if we're over the cap.
                if len(self._history) >= self.MAX_SESSIONS:
                    oldest = next(iter(self._history))
                    self._history.pop(oldest, None)
                hist = deque(maxlen=self.HISTORY_TURNS * 2)
                self._history[session_id] = hist
            return hist

    def reset(self, session_id: Optional[str]) -> None:
        if not session_id:
            return
        with self._lock:
            self._history.pop(session_id, None)

    # ── Chat ────────────────────────────────────────────────────────────────

    async def chat(
        self,
        message: str,
        context: Optional[MascotContext] = None,
        lang: str = "en",
        session_id: Optional[str] = None,
    ) -> str:
        lang = _normalize_lang(lang)
        system_prompt = SYSTEM_PROMPTS.get(lang, SYSTEM_PROMPTS["en"])

        messages: List[dict] = [{"role": "system", "content": system_prompt}]
        context_msg = _build_context_message(context, lang)
        if context_msg:
            messages.append({"role": "system", "content": context_msg})

        history = self._get_history(session_id)
        if history is not None:
            messages.extend(history)

        messages.append({"role": "user", "content": message})

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=500,
                temperature=0.7,
            )
            reply = response.choices[0].message.content or EMPTY_REPLIES[lang]
        except Exception as e:
            print(f"[ERROR] MascotService OpenAI error: {e}")
            return ERROR_REPLIES[lang]

        # Persist the turn into history for next call.
        if history is not None:
            history.append({"role": "user", "content": message})
            history.append({"role": "assistant", "content": reply})

        return reply


# ── Module-level singleton ──────────────────────────────────────────────────

_service: Optional[MascotService] = None


def get_mascot_service() -> MascotService:
    global _service
    if _service is None:
        _service = MascotService()
    return _service
