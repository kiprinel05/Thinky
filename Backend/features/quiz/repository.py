from core.base.repository import BaseRepository
from features.quiz.models import QuizResult
from features.quiz.schemas import QuizResultResponse

class QuizRepository(BaseRepository[QuizResult, QuizResultResponse, QuizResultResponse]):
    pass
