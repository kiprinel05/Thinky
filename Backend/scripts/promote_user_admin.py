"""
Promote a registered user to admin by email (for workshop verification UI).

Usage (from Backend/):
  python scripts/promote_user_admin.py admin@example.com

Requires DATABASE_URL.
"""
import sys

from sqlalchemy.orm import Session

from core.database import SessionLocal
from features.auth.models import User


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python scripts/promote_user_admin.py <email>")
        sys.exit(1)
    email = sys.argv[1].strip().lower()
    db: Session = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            print(f"No user with email: {email}")
            sys.exit(1)
        if user.is_guest:
            print("Guest accounts cannot be admins.")
            sys.exit(1)
        user.is_admin = True
        db.commit()
        print(f"[OK] {email} is now admin (user id={user.id})")
    finally:
        db.close()


if __name__ == "__main__":
    main()
