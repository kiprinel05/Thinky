from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from database import get_db
from models.user_model import User
from models.mission_model import QuizResult as QuizResultModel
from api.schemas.quiz_schemas import QuizResponse, QuizSubmission, QuizResult, Question, AnswerOption
from api.dependencies import get_current_user

router = APIRouter(prefix="/quiz", tags=["Quiz"])

QUIZ_QUESTIONS = [
    {
        "id": 1,
        "question": "What is Artificial Intelligence, really?",
        "options": [
            {"id": 1, "text": "An invisible robot that lives inside your phone."},
            {"id": 2, "text": "A kind of magic that guesses what you think."},
            {"id": 3, "text": "A smart computer program that can learn to do new things."},
            {"id": 4, "text": "A very powerful battery."}
        ],
        "correct_answer_id": 3,
        "explanation": "Exactly! AI is like a very fast student. It is a set of instructions (code) written by people, which can learn from examples."
    },
    {
        "id": 2,
        "question": "How does Artificial Intelligence learn to recognize a cat in a picture?",
        "options": [
            {"id": 1, "text": "It looks at thousands of pictures of cats until it understands what a cat looks like."},
            {"id": 2, "text": "It asks another cat."},
            {"id": 3, "text": "It just guesses and gets lucky every time."},
            {"id": 4, "text": "It has real eyes and sees exactly like we do."}
        ],
        "correct_answer_id": 1,
        "explanation": "Correct! This is called \"training\". The more examples (data) it sees, the smarter it becomes."
    },
    {
        "id": 3,
        "question": "Where have you already met Artificial Intelligence, maybe without knowing?",
        "options": [
            {"id": 1, "text": "When you tie your shoelaces."},
            {"id": 2, "text": "When you eat cereal in the morning."},
            {"id": 3, "text": "When YouTube or TikTok recommends a video you like."},
            {"id": 4, "text": "When you write with a pen on paper."}
        ],
        "correct_answer_id": 3,
        "explanation": "Bingo! Recommendation algorithms are AI. They \"learn\" what you like and try to show you more similar things."
    },
    {
        "id": 4,
        "question": "What can Artificial Intelligence NOT do (yet)?",
        "options": [
            {"id": 1, "text": "Play chess better than a human."},
            {"id": 2, "text": "Write a poem or a short story."},
            {"id": 3, "text": "Draw a colorful picture."},
            {"id": 4, "text": "Have real feelings (to be happy or sad)."}
        ],
        "correct_answer_id": 4,
        "explanation": "Very good! AI can imitate emotions, but it doesn’t feel anything. It has no heart or consciousness; it is just math and code."
    },
    {
        "id": 5,
        "question": "What is the best way to use Artificial Intelligence?",
        "options": [
            {"id": 1, "text": "Let it do all our homework so we don’t have to learn anything."},
            {"id": 2, "text": "Be afraid of it and shut it down."},
            {"id": 3, "text": "Use it as a helper (copilot) to be more creative and faster."},
            {"id": 4, "text": "Let it rule the world by itself."}
        ],
        "correct_answer_id": 3,
        "explanation": "Great attitude! AI is a tool. The best results happen when humans and AI work together as a team."
    }
]

@router.get("/questions", response_model=QuizResponse)
async def get_quiz_questions():
    """Get all quiz questions"""
    questions = [
        Question(
            id=q["id"],
            question=q["question"],
            options=[AnswerOption(id=opt["id"], text=opt["text"]) for opt in q["options"]],
            correct_answer_id=q["correct_answer_id"],
            explanation=q["explanation"]
        )
        for q in QUIZ_QUESTIONS
    ]
    return QuizResponse(
        questions=questions,
        total_questions=len(questions)
    )

@router.post("/submit", response_model=QuizResult)
async def submit_quiz(
    submission: QuizSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit quiz answers and get results"""
    correct_count = 0
    total = len(QUIZ_QUESTIONS)
    
    question_map = {q["id"]: q["correct_answer_id"] for q in QUIZ_QUESTIONS}
    
    for answer in submission.answers:
        correct_answer_id = question_map.get(answer.question_id)
        if correct_answer_id and answer.answer_id == correct_answer_id:
            correct_count += 1
    
    score = correct_count
    percentage = (correct_count / total) * 100 if total > 0 else 0
    incorrect_count = total - correct_count
    
    # Save quiz result to database
    quiz_result = QuizResultModel(
        user_id=current_user.id,
        quiz_type="introduction",
        score=score,
        total_questions=total,
        percentage=percentage,
        correct_answers=correct_count,
        incorrect_answers=incorrect_count
    )
    
    db.add(quiz_result)
    db.commit()
    db.refresh(quiz_result)
    
    return QuizResult(
        score=score,
        total_questions=total,
        percentage=percentage,
        correct_answers=correct_count,
        incorrect_answers=incorrect_count
    )

