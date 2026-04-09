"""
Add columns for workshop verification and admin users.
Safe to run multiple times (skips existing columns).

Usage (from Backend/):
  python scripts/add_workshop_verified_and_admin_columns.py

Requires DATABASE_URL (or uses sqlite test.db like core.database).
"""
from sqlalchemy import text

from core.database import engine


def _sqlite_columns(conn, table: str) -> set:
    rows = conn.execute(text(f"PRAGMA table_info({table})")).fetchall()
    return {r[1] for r in rows}


def main() -> None:
    url = str(engine.url)
    with engine.connect() as conn:
        if "sqlite" in url:
            users_cols = _sqlite_columns(conn, "users")
            if "is_admin" not in users_cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT 0"))
                conn.commit()
                print("[OK] users.is_admin added")
            else:
                print("[SKIP] users.is_admin already exists")

            wm_cols = _sqlite_columns(conn, "workshop_missions")
            if "is_verified" not in wm_cols:
                conn.execute(
                    text(
                        "ALTER TABLE workshop_missions ADD COLUMN is_verified BOOLEAN NOT NULL DEFAULT 0"
                    )
                )
                conn.commit()
                print("[OK] workshop_missions.is_verified added")
            else:
                print("[SKIP] workshop_missions.is_verified already exists")
            wm_cols = _sqlite_columns(conn, "workshop_missions")
            if "verified_at" not in wm_cols:
                conn.execute(
                    text("ALTER TABLE workshop_missions ADD COLUMN verified_at DATETIME")
                )
                conn.commit()
                print("[OK] workshop_missions.verified_at added")
            else:
                print("[SKIP] workshop_missions.verified_at already exists")
        else:
            # SQL Server / PostgreSQL: run equivalent ALTERs manually or use Alembic
            print(
                "[INFO] Non-sqlite URL. Add columns manually:\n"
                "  users: is_admin BIT/BOOLEAN NOT NULL DEFAULT 0\n"
                "  workshop_missions: is_verified BIT/BOOLEAN NOT NULL DEFAULT 0, verified_at DATETIME/TIMESTAMPTZ NULL"
            )


if __name__ == "__main__":
    main()
