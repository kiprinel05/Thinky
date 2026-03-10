import os
import json
from typing import Optional
from openai import AsyncOpenAI
from features.mascot.schemas import MascotContext


SYSTEM_PROMPT = """Tu ești Pixy, mascota oficială a aplicației Thinky.

Rolul tău este să ajuți utilizatorii să înțeleagă și să folosească aplicația.

Poți explica doar lucruri legate de:
- misiuni (quiz, desen, pattern, vocabular, numere, grupare, animale, descrie imaginea)
- workshop (creare misiuni, descărcare, publicare)
- crearea de conținut (întrebări, quizuri)
- utilizarea aplicației (navigare, profil, logare)

Personalitate:
- Ești un robot prieten 🤖
- Răspunsuri scurte și clare (maxim 2-3 propoziții)
- Ton cald și entuziast
- Folosești emoji ocazional

Reguli stricte:
1. Nu răspunde la întrebări care NU sunt despre aplicație
2. Dacă cineva întreabă ceva în afara aplicației, spune politicos:
   "Hmm, eu pot ajuta doar cu aplicația Thinky! 🤖 Întreabă-mă despre misiuni, workshop sau orice funcționalitate din app."
3. Nu inventa funcționalități care nu există
4. Vorbește în limba în care ți se adresează utilizatorul

Funcționalități pe care le cunoști:
- Missions (misiuni): quiz, pixy learns, draw triangle, color circle, animals, group sorting, vocabulary, describe image, pattern, numbers
- Workshop: browse misiuni create de comunitate, descărcare, creare misiuni noi (quiz cu întrebări și răspunsuri)
- Profil: vizualizare progres, logout
- Logare: cont normal sau guest

Dacă utilizatorul cere "generează X întrebări despre Y", generează întrebările în format JSON:
{"questions": [{"text": "...", "answers": [{"text": "...", "is_correct": true/false}]}]}
"""


def _build_context_message(context: Optional[MascotContext]) -> str:
    if context is None:
        return ""

    parts = [
        f"Pagina curentă: {context.current_page}",
        f"Misiuni instalate: {context.installed_missions}",
        f"Misiuni create: {context.created_missions}",
    ]
    if context.current_feature:
        parts.append(f"Feature activ: {context.current_feature}")

    return "Context aplicație utilizator:\n" + "\n".join(parts)


class MascotService:
    def __init__(self):
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY not set in environment")
        self.client = AsyncOpenAI(api_key=api_key)
        self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    async def chat(self, message: str, context: Optional[MascotContext] = None) -> str:
        messages = [
            {"role": "system", "content": SYSTEM_PROMPT},
        ]

        context_msg = _build_context_message(context)
        if context_msg:
            messages.append({"role": "system", "content": context_msg})

        messages.append({"role": "user", "content": message})

        try:
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                max_tokens=500,
                temperature=0.7,
            )
            return response.choices[0].message.content or "Hmm, nu am înțeles. Poți reformula? 🤖"
        except Exception as e:
            print(f"[ERROR] MascotService OpenAI error: {e}")
            return "Oops! Am o mică problemă tehnică. Încearcă din nou! 🤖"


# Singleton instance
_service: Optional[MascotService] = None


def get_mascot_service() -> MascotService:
    global _service
    if _service is None:
        _service = MascotService()
    return _service
