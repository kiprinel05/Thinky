from typing import List
from core.base.service import BaseService
from features.quiz.models import QuizResult
from features.quiz.schemas import (
    QuizResultResponse, QuizSubmission, QuizResponse, Question, AnswerOption
)
from features.quiz.repository import QuizRepository

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

class QuizService(BaseService[QuizResult, QuizResultResponse, QuizResultResponse]):
    def __init__(self, repository: QuizRepository):
        super().__init__(repository)
        self.repository = repository

    def get_questions(self) -> QuizResponse:
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

    def submit_quiz(self, user_id: int, submission: QuizSubmission) -> QuizResultResponse:
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
        quiz_result = QuizResult(
            user_id=user_id,
            quiz_type="introduction",
            score=score,
            total_questions=total,
            percentage=percentage,
            correct_answers=correct_count,
            incorrect_answers=incorrect_count
        )
        
        self.repository.db.add(quiz_result)
        self.repository.db.commit()
        self.repository.db.refresh(quiz_result)
        
        return QuizResultResponse.model_validate(quiz_result)
