"""
Script to create password_reset_codes table if it doesn't exist.
Run this if you get database errors related to password_reset_codes table.
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))

from database import init_db, Base, engine
from models.password_reset_model import PasswordResetCode

if __name__ == "__main__":
    try:
        print("Creating password_reset_codes table...")
        PasswordResetCode.__table__.create(bind=engine, checkfirst=True)
        print("[OK] Table created or already exists")
    except Exception as e:
        print(f"[ERROR] Failed to create table: {e}")
        import traceback
        traceback.print_exc()

