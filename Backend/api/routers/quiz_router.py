from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from database import get_db
from api.schemas.quiz_schemas import QuizResponse, QuizSubmission, QuizResult, Question, AnswerOption

router = APIRouter(prefix="/quiz", tags=["Quiz"])

QUIZ_QUESTIONS = [
    {
        "id": 1,
        "question": "Can AI recognize objects in images?",
        "options": [
            {"id": 1, "text": "Yes, AI can identify and classify objects in photos"},
            {"id": 2, "text": "No, AI cannot see or understand images"},
            {"id": 3, "text": "Only sometimes, depending on the image quality"},
            {"id": 4, "text": "AI can only recognize text, not objects"}
        ],
        "correct_answer_id": 1,
        "explanation": "Yes! AI uses computer vision to recognize and classify objects in images. This is how photo apps can identify people, animals, and objects."
    },
    {
        "id": 2,
        "question": "Can AI understand human emotions?",
        "options": [
            {"id": 1, "text": "Yes, AI can fully understand all human emotions"},
            {"id": 2, "text": "No, AI cannot feel or understand emotions"},
            {"id": 3, "text": "AI can detect emotions from facial expressions and text, but doesn't feel them"},
            {"id": 4, "text": "AI can only understand happy emotions"}
        ],
        "correct_answer_id": 3,
        "explanation": "AI can detect and analyze emotions from facial expressions, voice tone, and text, but it doesn't actually feel emotions itself. It's like recognizing patterns!"
    },
    {
        "id": 3,
        "question": "Can AI learn from examples?",
        "options": [
            {"id": 1, "text": "No, AI needs to be programmed for everything"},
            {"id": 2, "text": "Yes, AI can learn patterns from many examples"},
            {"id": 3, "text": "Only if the examples are perfect"},
            {"id": 4, "text": "AI can only learn from text, not images"}
        ],
        "correct_answer_id": 2,
        "explanation": "Yes! This is called machine learning. AI learns by seeing many examples and finding patterns, just like how you learn to recognize cats after seeing many pictures of cats!"
    },
    {
        "id": 4,
        "question": "Can AI make decisions on its own?",
        "options": [
            {"id": 1, "text": "Yes, AI can think and decide like humans"},
            {"id": 2, "text": "No, AI only follows instructions"},
            {"id": 3, "text": "AI can make decisions based on patterns it learned, but within programmed limits"},
            {"id": 4, "text": "AI can only make simple decisions"}
        ],
        "correct_answer_id": 3,
        "explanation": "AI can make decisions based on what it learned, but it works within the rules and limits that humans programmed. It's like a very smart assistant that follows guidelines!"
    },
    {
        "id": 5,
        "question": "Can AI create original art?",
        "options": [
            {"id": 1, "text": "No, AI can only copy existing art"},
            {"id": 2, "text": "Yes, AI can create completely original art from scratch"},
            {"id": 3, "text": "AI can create new combinations based on learned patterns"},
            {"id": 4, "text": "AI can only create simple drawings"}
        ],
        "correct_answer_id": 3,
        "explanation": "AI can create new art by combining patterns it learned from many examples. It's like learning different art styles and then creating something new that combines them!"
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
async def submit_quiz(submission: QuizSubmission, db: Session = Depends(get_db)):
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
    
    return QuizResult(
        score=score,
        total_questions=total,
        percentage=percentage,
        correct_answers=correct_count,
        incorrect_answers=incorrect_count
    )

