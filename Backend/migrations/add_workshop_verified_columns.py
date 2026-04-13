"""
One-time migration: add is_verified and verified_at columns to workshop_missions.
"""

from sqlalchemy import text, inspect
from core.database import engine


def migrate() -> None:
    inspector = inspect(engine)

    if "workshop_missions" not in inspector.get_table_names():
        print("[MIGRATION] workshop_missions table does not exist — skipping.")
        return

    columns = [c["name"] for c in inspector.get_columns("workshop_missions")]

    with engine.begin() as conn:
        if "is_verified" not in columns:
            conn.execute(
                text("ALTER TABLE workshop_missions ADD is_verified BIT NOT NULL DEFAULT 0")
            )
            print("[MIGRATION] Added is_verified column to workshop_missions.")
        else:
            print("[MIGRATION] is_verified already exists — skipping.")

        if "verified_at" not in columns:
            conn.execute(
                text("ALTER TABLE workshop_missions ADD verified_at DATETIMEOFFSET NULL")
            )
            print("[MIGRATION] Added verified_at column to workshop_missions.")
        else:
            print("[MIGRATION] verified_at already exists — skipping.")


if __name__ == "__main__":
    migrate()
