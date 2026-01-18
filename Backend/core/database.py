from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.declarative import declarative_base
import urllib.parse
from core.config import settings

# Setup SQLAlchemy connection
DATABASE_URL = settings.DATABASE_URL

if not DATABASE_URL:
    # Fail safe or mock for testing if no DB configured
    print("[WARNING] No DATABASE_URL set. Using sqlite in-memory for safety.")
    DATABASE_URL = "sqlite:///./test.db"

connect_args = {}

# Azure SQL specific handling for ADO.NET strings if passed directly
if "Active Directory" in str(DATABASE_URL) or settings.USE_AZURE_AD:
    connect_args["timeout"] = 10
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

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
