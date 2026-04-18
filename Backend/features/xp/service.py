from sqlalchemy import func as sa_func
from sqlalchemy.orm import Session

from features.auth.models import User
from features.quiz.models import QuizResult
from features.xp.schemas import AwardXpRequest, AwardXpResponse, MissionXpDetail, UserXpResponse

VALID_MISSION_SLUGS = {
    "pixy_learns",
    "animals",
    "draw_shapes",
    "color_circle",
    "group_images",
}


def compute_xp(score_percentage: float) -> int:
    if score_percentage >= 80:
        return 50
    if score_percentage >= 50:
        return 30
    return 10


class XpService:
    def __init__(self, db: Session):
        self.db = db

    def award_xp(self, user: User, req: AwardXpRequest) -> AwardXpResponse:
        # Guests cannot earn XP. We return a zero-award response with the
        # `is_guest` flag so the frontend can decide to show an upgrade prompt.
        # No row is persisted → guests will never show up on the leaderboard.
        if user.is_guest:
            return AwardXpResponse(
                xp_earned=0,
                mission_slug=req.mission_slug,
                already_awarded=False,
                is_guest=True,
            )

        is_workshop = req.mission_slug.startswith("workshop_")
        if req.mission_slug not in VALID_MISSION_SLUGS and not is_workshop:
            raise ValueError(f"Unknown mission slug: {req.mission_slug}")

        existing = (
            self.db.query(QuizResult)
            .filter(
                QuizResult.user_id == user.id,
                QuizResult.quiz_type == req.mission_slug,
            )
            .first()
        )

        if existing:
            return AwardXpResponse(
                xp_earned=existing.xp_earned,
                mission_slug=req.mission_slug,
                already_awarded=True,
            )

        xp = compute_xp(req.score_percentage)

        result = QuizResult(
            user_id=user.id,
            quiz_type=req.mission_slug,
            score=int(req.score_percentage),
            total_questions=1,
            percentage=req.score_percentage,
            correct_answers=1 if req.score_percentage >= 50 else 0,
            incorrect_answers=0 if req.score_percentage >= 50 else 1,
            xp_earned=xp,
        )
        self.db.add(result)
        self.db.commit()
        self.db.refresh(result)

        return AwardXpResponse(
            xp_earned=xp,
            mission_slug=req.mission_slug,
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
