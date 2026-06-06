"""Integration tests for /quiz routes via TestClient."""
from core.config import settings
from features.quiz.service import QUIZ_QUESTIONS

API = settings.API_V1_STR


class TestQuestionsRoute:
    def test_get_questions_returns_five_without_auth(self, client):
        # Act
        resp = client.get(f"{API}/quiz/questions")
        # Assert
        assert resp.status_code == 200
        body = resp.json()
        assert body["total_questions"] == 5
        assert len(body["questions"]) == 5
        for q in body["questions"]:
            assert "id" in q
            assert "question" in q
            assert len(q["options"]) == 4


class TestSubmitRoute:
    def test_submit_without_token_returns_401(self, client):
        resp = client.post(f"{API}/quiz/submit", json={"answers": []})
        assert resp.status_code == 401

    def test_submit_perfect_returns_50_xp(self, authed_client):
        client, user = authed_client
        answers = [
            {"question_id": q["id"], "answer_id": q["correct_answer_id"]}
            for q in QUIZ_QUESTIONS
        ]
        resp = client.post(f"{API}/quiz/submit", json={"answers": answers})
        assert resp.status_code == 200
        body = resp.json()
        assert body["score"] == 5
        assert body["percentage"] == 100.0
        assert body["xp_earned"] == 50

    def test_submit_empty_returns_10_xp(self, authed_client):
        client, user = authed_client
        resp = client.post(f"{API}/quiz/submit", json={"answers": []})
        assert resp.status_code == 200
        body = resp.json()
        assert body["score"] == 0
        assert body["xp_earned"] == 10
