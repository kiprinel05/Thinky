from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from core.database import get_db
from features.auth.dependencies import get_current_user
from features.auth.models import User
from features.quiz.schemas import QuizResponse, QuizResultResponse, QuizSubmission
from features.quiz.service import QuizService
from features.quiz.repository import QuizRepository
from features.quiz.models import QuizResult

router = APIRouter(prefix="/quiz", tags=["Quiz"])

def get_quiz_service(db: Session = Depends(get_db)) -> QuizService:
    repository = QuizRepository(QuizResult, db)
    return QuizService(repository)

@router.get("/questions", response_model=QuizResponse)
async def get_quiz_questions(service: QuizService = Depends(get_quiz_service)):
    return service.get_questions()

@router.post("/submit", response_model=QuizResultResponse)
async def submit_quiz(
    submission: QuizSubmission,
    current_user: User = Depends(get_current_user),
    service: QuizService = Depends(get_quiz_service)
):
    return service.submit_quiz(current_user.id, submission)
