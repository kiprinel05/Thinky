"""
One-time migration: add xp_earned column to quiz_results and backfill existing rows.

Run manually:
    python -m migrations.add_xp_earned_to_quiz_results

Or it will be applied automatically on startup via main.py.
"""

from sqlalchemy import text, inspect
from core.database import engine


def migrate() -> None:
    inspector = inspect(engine)
    columns = [c["name"] for c in inspector.get_columns("quiz_results")]

    if "xp_earned" in columns:
        print("[MIGRATION] xp_earned column already exists — skipping.")
        return

    with engine.begin() as conn:
        conn.execute(
            text("ALTER TABLE quiz_results ADD xp_earned INTEGER NOT NULL DEFAULT 0")
        )

        conn.execute(text("""
            UPDATE quiz_results
            SET xp_earned = CASE
                WHEN percentage >= 80 THEN 50
                WHEN percentage >= 50 THEN 30
                ELSE 10
            END
        """))

    print("[MIGRATION] Added xp_earned column and backfilled existing rows.")


if __name__ == "__main__":
    migrate()
