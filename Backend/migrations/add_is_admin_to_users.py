"""
One-time migration: add is_admin column to users table.
Applied automatically on startup via main.py.
"""

from sqlalchemy import text, inspect
from core.database import engine


def migrate() -> None:
    inspector = inspect(engine)
    columns = [c["name"] for c in inspector.get_columns("users")]

    if "is_admin" in columns:
        print("[MIGRATION] is_admin column already exists — skipping.")
        return

    with engine.begin() as conn:
        conn.execute(
            text("ALTER TABLE users ADD is_admin BIT NOT NULL DEFAULT 0")
        )

    print("[MIGRATION] Added is_admin column to users table.")


if __name__ == "__main__":
    migrate()
