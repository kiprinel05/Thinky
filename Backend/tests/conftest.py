"""
Global pytest fixtures for the Thinky backend test suite.

Loaded before any test module is collected. We set required env vars here
because `core.config.Settings` reads SECRET_KEY / DATABASE_URL at import time.

The FastAPI `app` is imported lazily inside the `client` fixture so that
schema- and service-level tests don't have to pull in heavy/optional deps
(openai, torch, ...) just to validate a Pydantic model.
"""
import os
import sys
import types
from unittest.mock import MagicMock

# Must run BEFORE any `core.*` import below.
os.environ.setdefault("SECRET_KEY", "test-secret-key-do-not-use-in-prod")
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")

# Inject a minimal fake `openai` module so importing `main` (which transitively
# imports features.mascot.service) doesn't require the real package in dev
# environments where it isn't installed. If openai *is* installed, we keep it.
if "openai" not in sys.modules:
    try:
        import openai  # noqa: F401
    except ImportError:
        fake = types.ModuleType("openai")
        fake.AsyncOpenAI = MagicMock
        fake.OpenAI = MagicMock
        sys.modules["openai"] = fake

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import core.database as _core_database

# Some legacy modules (e.g. features.workshop.models) try to `from database import Base`
# first and only fall back to `core.database` on ImportError. The legacy `database.py`
# at the project root creates its OWN declarative Base, so tables registered there
# never end up on `core.database.Base`. Alias the module here so both import paths
# resolve to the same Base and tests can rely on `Base.metadata.create_all`.
sys.modules.setdefault("database", _core_database)

# Block the legacy `models.user_model` so workshop.service and friends fall through
# to `features.auth.models.User`. Otherwise we'd register the `users` table twice
# on the same Base and SQLAlchemy errors at import time.
sys.modules["models.user_model"] = None

from core.database import Base, get_db

# Register models we touch in service / router tests so create_all knows about them.
# Schema-only tests don't use db_session, so they pay nothing for these imports.
from features.auth.models import PasswordResetCode, User  # noqa: F401
from features.quiz.models import QuizResult  # noqa: F401
from features.mission.models import Mission, MissionProgress  # noqa: F401
from features.workshop.models import WorkshopDownload, WorkshopMission  # noqa: F401


@pytest.fixture
def db_session():
    """Fresh in-memory SQLite session per test.

    StaticPool + check_same_thread=False is required so TestClient (which may
    use a separate thread for the request) sees the same in-memory database.
    """
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


@pytest.fixture
def client(db_session):
    """FastAPI TestClient with `get_db` overridden to share the test session.

    `app` is imported here (not at module scope) so that tests which only need
    `db_session` don't trigger loading of every feature router (and its deps).
    """
    from fastapi.testclient import TestClient
    from main import app

    def _override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture
def authed_client(db_session):
    """TestClient where `get_current_user` returns a real registered User row.

    The user is persisted to db_session so routes that re-fetch by id work.
    Returns (client, user) so tests can assert against the actual id/email.
    """
    from fastapi.testclient import TestClient
    from main import app
    from features.auth.dependencies import get_current_user

    user = User(
        id=1,
        username="testuser",
        email="testuser@example.com",
        hashed_password="placeholder",
        is_guest=False,
        is_admin=False,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    def _override_get_db():
        yield db_session

    def _override_current_user():
        return user

    app.dependency_overrides[get_db] = _override_get_db
    app.dependency_overrides[get_current_user] = _override_current_user
    with TestClient(app) as c:
        yield c, user
    app.dependency_overrides.clear()
