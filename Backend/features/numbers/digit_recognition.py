"""Handwritten digit recognition (0–9) for the Numbers mission.

A small CNN trained on MNIST (+ optionally the Kaggle "Handwritten Digits
Dataset (not in MNIST)" by jcprogjava) is the underlying recognizer. The
service exposes both:

* :meth:`recognize_truth` — the raw ML prediction. Used by the service layer
  for cheating detection (Pixy "knows" what the kid actually drew).
* :meth:`recognize` / :meth:`apply_persona` — wraps the raw prediction with a
  per-level persona (junior is unsure and often wrong, expert is near-perfect).
  This is what gets shown to the child.

If the trained model file is missing, a small heuristic fallback is used so
the mission still works out of the box. To produce the model file, run from
the ``Backend/`` directory::

    python -m scripts.train_digit_recognizer
    # or, augmenting MNIST with the Kaggle dataset:
    python -m scripts.train_digit_recognizer --kaggle path/to/kaggle/dataset
"""

from __future__ import annotations

import io
import random
import threading
from pathlib import Path
from typing import Tuple

import numpy as np
from PIL import Image

MODEL_PATH = Path(__file__).parent / "models" / "digit_cnn.pt"


class DigitRecognitionService:
    # ── Bilingual hints (used by the professor overlay) ──────────────────────

    DIGIT_HINTS = {
        "ro": {
            0: "Cifra 0 este un cerc, ca un ou.",
            1: "Cifra 1 este o linie dreaptă, de sus în jos.",
            2: "Cifra 2 are o curbă sus și o linie orizontală jos.",
            3: "Cifra 3 are două curbe rotunde, una deasupra celeilalte.",
            4: "Cifra 4 are o linie verticală, una orizontală și încă una verticală.",
            5: "Cifra 5 are o linie orizontală sus și o curbă jos.",
            6: "Cifra 6 are o curbă în jos și un mic cerc la bază.",
            7: "Cifra 7 are o linie orizontală sus și una oblică în jos.",
            8: "Cifra 8 are două cercuri, unul peste altul.",
            9: "Cifra 9 are un cerc sus și o linie în jos.",
        },
        "en": {
            0: "The digit 0 is a circle, like an oval.",
            1: "The digit 1 is a straight line from top to bottom.",
            2: "The digit 2 has a curve on top and a horizontal line at the bottom.",
            3: "The digit 3 has two round curves, one above the other.",
            4: "The digit 4 has a vertical line, a horizontal one and another vertical.",
            5: "The digit 5 has a horizontal line on top and a curve at the bottom.",
            6: "The digit 6 has a downward curve and a small circle at the bottom.",
            7: "The digit 7 has a top line and a diagonal line going down.",
            8: "The digit 8 has two circles, one on top of the other.",
            9: "The digit 9 has a circle on top and a line going down.",
        },
    }

    DIGIT_HINT_FALLBACK = {
        "ro": "Încearcă să desenezi cifra clar, în mijlocul ecranului.",
        "en": "Try to draw the digit clearly, in the middle of the screen.",
    }

    def __init__(self) -> None:
        self._model = None
        self._device = None
        self._torch = None
        self._load_lock = threading.Lock()
        self._tried_load = False

    # ── Lazy CNN loading ─────────────────────────────────────────────────────

    def _ensure_model(self) -> bool:
        """Lazily load the CNN. Returns True iff the trained model is usable."""
        if self._model is not None:
            return True
        if self._tried_load:
            return False
        with self._load_lock:
            if self._tried_load:
                return self._model is not None
            self._tried_load = True
            try:
                import torch
                import torch.nn as nn

                class _DigitCNN(nn.Module):
                    """Architecture must match scripts/train_digit_recognizer.py."""

                    def __init__(self) -> None:
                        super().__init__()
                        self.conv1 = nn.Conv2d(1, 32, 3, padding=1)
                        self.conv2 = nn.Conv2d(32, 64, 3, padding=1)
                        self.pool = nn.MaxPool2d(2, 2)
                        self.fc1 = nn.Linear(64 * 7 * 7, 128)
                        self.fc2 = nn.Linear(128, 10)
                        self.dropout = nn.Dropout(0.3)

                    def forward(self, x):
                        x = self.pool(torch.relu(self.conv1(x)))
                        x = self.pool(torch.relu(self.conv2(x)))
                        x = x.view(x.size(0), -1)
                        x = torch.relu(self.fc1(x))
                        x = self.dropout(x)
                        return self.fc2(x)

                if not MODEL_PATH.exists():
                    print(
                        f"[digit_recognition] No trained model at {MODEL_PATH}. "
                        f"Run `python -m scripts.train_digit_recognizer` from "
                        f"the Backend/ folder to train one. Falling back to "
                        f"the simple heuristic recognizer in the meantime."
                    )
                    return False

                device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
                model = _DigitCNN()
                # `weights_only=True` is the safer load mode in torch ≥ 2.4.
                try:
                    state = torch.load(MODEL_PATH, map_location=device, weights_only=True)
                except TypeError:
                    state = torch.load(MODEL_PATH, map_location=device)
                model.load_state_dict(state)
                model.to(device).eval()

                self._model = model
                self._device = device
                self._torch = torch
                print(
                    f"[digit_recognition] Loaded CNN from {MODEL_PATH} (device={device})."
                )
                return True
            except Exception as e:  # pragma: no cover — defensive
                print(f"[digit_recognition] Failed to load CNN: {e}. Using heuristic.")
                return False

    # ── Public API ───────────────────────────────────────────────────────────

    def recognize(self, image_bytes: bytes, model_level: str = "junior") -> Tuple[int, float]:
        """Return Pixy's *display* guess (with persona noise applied).

        Use :meth:`recognize_truth` for the underlying ML prediction (used by
        the service layer for cheating detection).
        """
        truth_digit, truth_conf = self.recognize_truth(image_bytes)
        return self.apply_persona(truth_digit, truth_conf, model_level)

    def recognize_truth(self, image_bytes: bytes) -> Tuple[int, float]:
        """Return the underlying ML prediction (no persona noise).

        Falls back to the simple heuristic if the model isn't available.
        """
        try:
            if self._ensure_model():
                tensor = self._preprocess_for_cnn(image_bytes)
                if tensor is None:
                    return (0, 0.0)
                torch = self._torch
                with torch.no_grad():
                    logits = self._model(tensor)
                    probs = torch.softmax(logits, dim=1)
                    conf, pred = probs.max(dim=1)
                    return (int(pred.item()), float(conf.item()))
            return self._heuristic_predict(image_bytes)
        except Exception as e:  # pragma: no cover — defensive
            print(f"[ERROR] Digit recognition failed: {e}")
            return (0, 0.0)

    def apply_persona(
        self,
        truth_digit: int,
        truth_conf: float,
        model_level: str,
    ) -> Tuple[int, float]:
        """Add persona noise so junior is unsure and expert near-perfect.

        The underlying ML prediction stays accurate so cheating detection can
        still rely on it; this only affects what Pixy *says* to the child.
        """
        if model_level == "junior":
            # Pixy is unsure: ~50% chance to swap to a wrong digit.
            if random.random() < 0.5:
                wrong = [d for d in range(10) if d != truth_digit]
                return (random.choice(wrong), round(random.uniform(0.20, 0.45), 2))
            return (truth_digit, round(min(truth_conf * 0.6, 0.55), 2))
        if model_level == "student":
            if random.random() < 0.20:
                wrong = [d for d in range(10) if d != truth_digit]
                return (random.choice(wrong), round(random.uniform(0.35, 0.60), 2))
            return (truth_digit, round(min(truth_conf * 0.85, 0.80), 2))
        # expert — show the real prediction, just clamp to leave room for "100%"
        # only after the simulated learning loop kicks in.
        return (truth_digit, round(min(truth_conf, 0.99), 2))

    # ── Preprocessing for the CNN ────────────────────────────────────────────

    def _preprocess_for_cnn(self, image_bytes: bytes):
        """Convert a canvas drawing to a normalized 28x28 tensor (MNIST-like)."""
        img = Image.open(io.BytesIO(image_bytes))
        # Composite onto white so transparent canvases don't end up "all stroke".
        if img.mode in ("RGBA", "LA") or (img.mode == "P" and "transparency" in img.info):
            bg = Image.new("RGB", img.size, (255, 255, 255))
            bg.paste(img, mask=img.split()[-1])
            img = bg
        img = img.convert("L")
        arr = np.array(img, dtype=np.uint8)

        # MNIST is light strokes on dark bg. If our canvas is dark on light,
        # invert; otherwise keep as-is.
        if arr.mean() > 127:
            arr = 255 - arr

        mask = arr > 60
        if not mask.any():
            return None

        ys, xs = np.where(mask)
        top, bottom = ys.min(), ys.max() + 1
        left, right = xs.min(), xs.max() + 1
        cropped = arr[top:bottom, left:right]

        # Scale so the longest side is 20px (MNIST convention: digit fits in 20x20).
        h, w = cropped.shape
        scale = 20.0 / max(h, w)
        new_h = max(1, int(round(h * scale)))
        new_w = max(1, int(round(w * scale)))
        pil = Image.fromarray(cropped).resize((new_w, new_h), Image.LANCZOS)
        resized = np.array(pil, dtype=np.float32)

        # Center in a 28x28 frame.
        canvas = np.zeros((28, 28), dtype=np.float32)
        top_pad = (28 - new_h) // 2
        left_pad = (28 - new_w) // 2
        canvas[top_pad : top_pad + new_h, left_pad : left_pad + new_w] = resized

        # Re-center by mass, like MNIST's preprocessing.
        cy, cx = self._center_of_mass(canvas)
        canvas = np.roll(canvas, int(round(14 - cy)), axis=0)
        canvas = np.roll(canvas, int(round(14 - cx)), axis=1)

        canvas = canvas / 255.0
        canvas = (canvas - 0.1307) / 0.3081

        torch = self._torch
        return torch.from_numpy(canvas).float().unsqueeze(0).unsqueeze(0).to(self._device)

    @staticmethod
    def _center_of_mass(img: np.ndarray) -> Tuple[float, float]:
        total = float(img.sum())
        if total <= 0:
            return (14.0, 14.0)
        ys, xs = np.indices(img.shape)
        cy = float((ys * img).sum() / total)
        cx = float((xs * img).sum() / total)
        return (cy, cx)

    # ── Heuristic fallback (only used when no trained model is on disk) ──────

    def _heuristic_predict(self, image_bytes: bytes) -> Tuple[int, float]:
        """Very rough geometry-based guess for 0–9.

        Picks a coarse bucket from aspect ratio + hole count. It's nowhere
        near as good as the CNN — its job is just to keep the mission playable
        before the user trains the model.
        """
        try:
            import cv2

            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if image is None:
                return (0, 0.0)
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            blurred = cv2.GaussianBlur(gray, (5, 5), 0)
            _, binary = cv2.threshold(
                blurred, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
            )
            contours, hierarchy = cv2.findContours(
                binary, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE
            )
            if not contours:
                return (0, 0.0)
            largest = max(contours, key=cv2.contourArea)
            if cv2.contourArea(largest) < 200:
                return (0, 0.0)
            x, y, w, h = cv2.boundingRect(largest)
            ar = h / w if w > 0 else 1.0
            holes = (
                sum(1 for hh in hierarchy[0] if hh[3] >= 0) if hierarchy is not None else 0
            )
            if holes >= 2:
                return (8, 0.4)
            if holes == 1:
                return (9 if ar > 1.4 else 0, 0.4)
            if ar > 2.2:
                return (1, 0.5)
            if ar > 1.4:
                return (random.choice([2, 3, 5, 7]), 0.3)
            return (random.choice([4, 6]), 0.3)
        except Exception:
            return (random.randint(0, 9), 0.1)

    # ── Hints (for the professor overlay) ────────────────────────────────────

    def get_hint(self, digit: int, lang: str = "en") -> str:
        code = (lang or "en").strip().lower()[:2]
        if code not in ("en", "ro"):
            code = "en"
        hints = self.DIGIT_HINTS.get(code, self.DIGIT_HINTS["en"])
        return hints.get(
            digit,
            self.DIGIT_HINT_FALLBACK.get(code, self.DIGIT_HINT_FALLBACK["en"]),
        )


# Singleton used across the app
digit_recognition_service = DigitRecognitionService()
