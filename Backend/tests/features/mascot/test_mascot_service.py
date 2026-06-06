"""Tests for MascotService — OpenAI client fully mocked."""
import os
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from features.mascot.schemas import MascotContext
from features.mascot.service import (
    EMPTY_REPLIES,
    ERROR_REPLIES,
    MascotService,
    _build_context_message,
    _normalize_lang,
)


class TestNormalizeLang:
    @pytest.mark.parametrize(
        "raw,expected",
        [
            (None, "en"),
            ("", "en"),
            ("en", "en"),
            ("en-US", "en"),
            ("ro", "ro"),
            ("ro-RO", "ro"),
            ("fr", "en"),       # unsupported → default
            ("en, ro;q=0.9", "en"),
        ],
    )
    def test_normalize(self, raw, expected):
        assert _normalize_lang(raw) == expected


class TestBuildContextMessage:
    def test_none_returns_empty_string(self):
        assert _build_context_message(None, "en") == ""

    def test_en_context_uses_english_labels(self):
        ctx = MascotContext(
            current_page="Profile",
            installed_missions=5,
            created_missions=2,
            current_feature="settings",
        )
        msg = _build_context_message(ctx, "en")
        assert "Current page: Profile" in msg
        assert "Installed missions: 5" in msg

    def test_ro_context_translates_known_page_names(self):
        ctx = MascotContext(
            current_page="Profile",
            installed_missions=5,
            created_missions=2,
            current_feature=None,
        )
        msg = _build_context_message(ctx, "ro")
        assert "Profil" in msg  # translated from "Profile"
        assert "Pagina curentă" in msg


@pytest.fixture
def service():
    # __init__ insists on OPENAI_API_KEY — set a placeholder and let the
    # AsyncOpenAI client be the (mocked) stand-in we control via attribute.
    with patch.dict(os.environ, {"OPENAI_API_KEY": "test-key"}):
        svc = MascotService()
    svc.client = MagicMock()
    # Build a chat completion that looks like the OpenAI SDK's response shape.
    response = MagicMock()
    response.choices = [MagicMock(message=MagicMock(content="Hi from Pixy"))]
    svc.client.chat.completions.create = AsyncMock(return_value=response)
    return svc


class TestChat:
    @pytest.mark.asyncio
    async def test_chat_returns_reply_from_openai(self, service):
        reply = await service.chat("Hello", lang="en", session_id="s1")
        assert reply == "Hi from Pixy"

    @pytest.mark.asyncio
    async def test_chat_returns_error_reply_on_openai_failure(self, service):
        service.client.chat.completions.create = AsyncMock(side_effect=RuntimeError("boom"))
        reply = await service.chat("Hello", lang="ro", session_id="s2")
        assert reply == ERROR_REPLIES["ro"]

    @pytest.mark.asyncio
    async def test_chat_persists_history_per_session(self, service):
        await service.chat("first", lang="en", session_id="abc")
        await service.chat("second", lang="en", session_id="abc")
        hist = service._history["abc"]
        # Each turn adds (user, assistant) = 2 entries; two turns = 4.
        assert len(hist) == 4
        roles = [m["role"] for m in hist]
        assert roles == ["user", "assistant", "user", "assistant"]


class TestReset:
    @pytest.mark.asyncio
    async def test_reset_clears_only_target_session(self, service):
        await service.chat("hey", session_id="a")
        await service.chat("hey", session_id="b")
        service.reset("a")
        assert "a" not in service._history
        assert "b" in service._history

    def test_reset_with_no_session_id_is_noop(self, service):
        service._history["x"] = "dummy"
        service.reset(None)
        assert "x" in service._history
