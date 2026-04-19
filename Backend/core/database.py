import time
import urllib.parse

from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker

from core.config import settings

# Setup SQLAlchemy connection
DATABASE_URL = settings.DATABASE_URL

if not DATABASE_URL:
    # Fail safe or mock for testing if no DB configured
    print("[WARNING] No DATABASE_URL set. Using sqlite in-memory for safety.")
    DATABASE_URL = "sqlite:///./test.db"

connect_args = {}

# Azure SQL specific handling for ADO.NET strings if passed directly.
#
# Azure SQL "serverless" tier auto-pauses after a period of inactivity. Waking
# it up on the next connection can take 30–60s. The default ODBC login timeout
# (10s) is way too aggressive — every cold start of the API would crash. Give
# the driver a generous per-attempt budget and rely on the explicit retry
# loop in :func:`wait_for_db` for graceful warm-up.
if "Active Directory" in str(DATABASE_URL) or settings.USE_AZURE_AD:
    connect_args["timeout"] = 60
    # Additional Azure AD handling logic could go here similar to original database.py
    # For now, we assume proper connection string formation in config.py or env

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    echo=False,
    connect_args=connect_args
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def wait_for_db(
    max_attempts: int = 6,
    initial_backoff: float = 5.0,
    backoff_multiplier: float = 1.6,
) -> bool:
    """Probe the database with retry-and-backoff so cold-started instances
    (e.g. Azure SQL serverless auto-resume) have time to wake up.

    Returns ``True`` once a connection succeeds, or ``False`` if every
    attempt times out. Total worst-case wait with the defaults is ~80s.
    """
    backoff = initial_backoff
    for attempt in range(1, max_attempts + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            if attempt > 1:
                print(f"[OK] Database is up after {attempt} attempts")
            return True
        except OperationalError as e:
            err = str(e).splitlines()[0] if str(e) else type(e).__name__
            if attempt >= max_attempts:
                print(
                    f"[ERROR] Database still unreachable after {attempt} attempts: {err}"
                )
                return False
            print(
                f"[INFO] Database not ready (attempt {attempt}/{max_attempts}): {err}"
                f" — retrying in {backoff:.0f}s (Azure serverless may be waking up)"
            )
            time.sleep(backoff)
            backoff *= backoff_multiplier
        except Exception as e:  # noqa: BLE001
            # Non-transient driver/config error — no point retrying.
            print(f"[ERROR] Database connection failed (non-retryable): {e}")
            return False
    return False


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
