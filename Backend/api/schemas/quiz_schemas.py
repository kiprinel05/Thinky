from pydantic import BaseModel
from typing import List, Optional

class AnswerOption(BaseModel):
    id: int
    text: str

class Question(BaseModel):
    id: int
    question: str
    options: List[AnswerOption]
    correct_answer_id: int
    explanation: str

class QuizResponse(BaseModel):
    questions: List[Question]
    total_questions: int

class AnswerSubmission(BaseModel):
    question_id: int
    answer_id: int

class QuizSubmission(BaseModel):
    answers: List[AnswerSubmission]

class QuizResult(BaseModel):
    score: int
    total_questions: int
    percentage: float
    correct_answers: int
    incorrect_answers: int

