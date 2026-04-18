"""
One-off cleanup: delete QuizResult rows that belong to guest users.

As of the guest-XP rule, only registered users accumulate XP. Historical rows
created before that rule was enforced are purged here so the leaderboard and
per-user totals stop accounting for guests.

Usage (from Backend/):
  python scripts/purge_guest_xp.py            # dry run — print what would be deleted
  python scripts/purge_guest_xp.py --apply    # actually delete

Requires DATABASE_URL.
"""
from __future__ import annotations

import argparse
import sys

from sqlalchemy.orm import Session

from core.database import SessionLocal
from features.auth.models import User
from features.quiz.models import QuizResult


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually delete rows. Without this flag, runs as a dry preview.",
    )
    args = parser.parse_args()

    db: Session = SessionLocal()
    try:
        guest_ids = [
            uid for (uid,) in db.query(User.id).filter(User.is_guest == True).all()  # noqa: E712
        ]
        if not guest_ids:
            print("[purge_guest_xp] No guest users found. Nothing to do.")
            return

        affected = (
            db.query(QuizResult)
            .filter(QuizResult.user_id.in_(guest_ids))
            .count()
        )
        total_xp = (
            db.query(QuizResult.xp_earned)
            .filter(QuizResult.user_id.in_(guest_ids))
            .all()
        )
        total = sum(int(x[0] or 0) for x in total_xp)

        print(f"[purge_guest_xp] Guest users:        {len(guest_ids)}")
        print(f"[purge_guest_xp] Guest XP rows:      {affected}")
        print(f"[purge_guest_xp] Guest XP sum:       {total}")

        if affected == 0:
            return

        if not args.apply:
            print("[purge_guest_xp] Dry run. Re-run with --apply to delete.")
            return

        deleted = (
            db.query(QuizResult)
            .filter(QuizResult.user_id.in_(guest_ids))
            .delete(synchronize_session=False)
        )
        db.commit()
        print(f"[purge_guest_xp] Deleted {deleted} rows. Leaderboard is now clean.")
    except Exception as e:
        db.rollback()
        print(f"[purge_guest_xp] Failed: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
