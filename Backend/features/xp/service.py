from sqlalchemy.orm import Session

from features.quiz.models import QuizResult
from features.xp.schemas import AwardXpRequest, AwardXpResponse

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

    def award_xp(self, user_id: int, req: AwardXpRequest) -> AwardXpResponse:
        is_workshop = req.mission_slug.startswith("workshop_")
        if req.mission_slug not in VALID_MISSION_SLUGS and not is_workshop:
            raise ValueError(f"Unknown mission slug: {req.mission_slug}")

        existing = (
            self.db.query(QuizResult)
            .filter(
                QuizResult.user_id == user_id,
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
            user_id=user_id,
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
