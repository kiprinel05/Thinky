from sqlalchemy import func as sa_func
from sqlalchemy.orm import Session

from features.auth.models import User
from features.quiz.models import QuizResult
from features.xp.schemas import AwardXpRequest, AwardXpResponse, MissionXpDetail, UserXpResponse

# Slugs the XP system accepts via POST /xp/award. Anything not in this set
# (and not prefixed with `workshop_`) is rejected with a 400.
#
# Quiz uses its own slug (`introduction`) inside QuizService.submit_quiz and
# does NOT need to be listed here.
VALID_MISSION_SLUGS = {
    # Mini-game missions
    "pixy_learns",
    "animals",
    "draw_shapes",
    "color_circle",
    "group_images",
    # Newer missions wired in below
    "numbers",
    "vocabulary",
    "describe",
    "pattern",
}


def compute_xp(score_percentage: float) -> int:
    """Tiered XP reward. Identical tiers are reused by QuizService."""
    if score_percentage >= 80:
        return 50
    if score_percentage >= 50:
        return 30
    return 10


class XpService:
    def __init__(self, db: Session):
        self.db = db

    # ── Public API used by the /xp/award route ─────────────────────────────

    def award_xp(self, user: User, req: AwardXpRequest) -> AwardXpResponse:
        return self.award_for_user(
            user=user,
            mission_slug=req.mission_slug,
            score_percentage=req.score_percentage,
        )

    # ── Reusable helper, callable from any feature service ────────────────

    def award_for_user(
        self,
        user: User,
        mission_slug: str,
        score_percentage: float,
    ) -> AwardXpResponse:
        """Idempotent XP grant for ``(user, mission_slug)``.

        Designed to be called either from the public /xp/award route or
        directly from a mission service (e.g. ``NumbersService.complete()``)
        once we centralise XP awards server-side. Guests get a zero-award
        response (no DB write); replays return ``already_awarded=True`` with
        the original amount so the leaderboard never inflates.
        """
        if user.is_guest:
            # Guests cannot earn XP. Returning an explicit zero-award response
            # with `is_guest=True` lets the UI prompt for sign-up without the
            # caller needing extra branching.
            return AwardXpResponse(
                xp_earned=0,
                mission_slug=mission_slug,
                already_awarded=False,
                is_guest=True,
            )

        is_workshop = mission_slug.startswith("workshop_")
        if mission_slug not in VALID_MISSION_SLUGS and not is_workshop:
            raise ValueError(f"Unknown mission slug: {mission_slug}")

        existing = (
            self.db.query(QuizResult)
            .filter(
                QuizResult.user_id == user.id,
                QuizResult.quiz_type == mission_slug,
            )
            .first()
        )

        if existing:
            return AwardXpResponse(
                xp_earned=existing.xp_earned,
                mission_slug=mission_slug,
                already_awarded=True,
            )

        # Clamp to [0, 100] so a buggy caller can't unlock an off-tier reward.
        pct = max(0.0, min(100.0, float(score_percentage)))
        xp = compute_xp(pct)

        result = QuizResult(
            user_id=user.id,
            quiz_type=mission_slug,
            score=int(pct),
            total_questions=1,
            percentage=pct,
            correct_answers=1 if pct >= 50 else 0,
            incorrect_answers=0 if pct >= 50 else 1,
            xp_earned=xp,
        )
        self.db.add(result)
        self.db.commit()
        self.db.refresh(result)

        return AwardXpResponse(
            xp_earned=xp,
            mission_slug=mission_slug,
            already_awarded=False,
        )

    def get_user_xp(self, user: User) -> UserXpResponse:
        # Guests don't participate in the XP system → return a clean zero state
        # instead of a confusing "rank N of M" that would reference only
        # registered players.
        if user.is_guest:
            return UserXpResponse(
                total_xp=0,
                rank=0,
                total_players=0,
                missions=[],
            )

        rows = (
            self.db.query(
                QuizResult.quiz_type,
                QuizResult.xp_earned,
            )
            .filter(QuizResult.user_id == user.id)
            .all()
        )

        missions = [MissionXpDetail(mission_slug=r.quiz_type, xp=r.xp_earned) for r in rows]
        total_xp = sum(m.xp for m in missions)

        # Rank only against non-guest players — matches leaderboard behaviour.
        all_users_xp = (
            self.db.query(
                QuizResult.user_id,
                sa_func.sum(QuizResult.xp_earned).label("total"),
            )
            .join(User, User.id == QuizResult.user_id)
            .filter(User.is_guest == False)  # noqa: E712
            .group_by(QuizResult.user_id)
            .all()
        )

        total_players = len(all_users_xp)
        rank = 1
        for row in all_users_xp:
            if float(row.total) > total_xp:
                rank += 1

        return UserXpResponse(
            total_xp=total_xp,
            rank=rank,
            total_players=total_players,
            missions=sorted(missions, key=lambda m: -m.xp),
        )
