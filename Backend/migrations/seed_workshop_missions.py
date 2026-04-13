"""
Seed 5 demo workshop quiz missions (2 verified).
Runs on startup — skips if missions already exist.
"""

import json
from datetime import datetime, timezone
from sqlalchemy import text, inspect
from core.database import engine

MISSIONS = [
    {
        "title": "How AI Learns From Data",
        "description": "Discover how artificial intelligence learns patterns from examples, just like you!",
        "tags": ["AI", "machine learning", "data"],
        "is_verified": True,
        "questions": [
            {
                "text": "What does AI need to learn how to recognize a cat in a photo?",
                "answers": [
                    {"text": "A single perfect photo"},
                    {"text": "Thousands of labeled example photos"},
                    {"text": "A written description of a cat"},
                    {"text": "A real cat next to the computer"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "What is 'training data'?",
                "answers": [
                    {"text": "Data that exercises the computer's muscles"},
                    {"text": "Examples with correct answers that AI studies to learn"},
                    {"text": "Secret codes only robots understand"},
                    {"text": "The battery power used during learning"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "When AI learns by being shown correct answers, this is called...",
                "answers": [
                    {"text": "Unsupervised learning"},
                    {"text": "Random guessing"},
                    {"text": "Supervised learning"},
                    {"text": "Copy-paste learning"},
                ],
                "correct_answer_index": 2,
            },
            {
                "text": "Why does AI get better with more training examples?",
                "answers": [
                    {"text": "It memorizes every single image pixel by pixel"},
                    {"text": "It finds patterns that help it recognize new things it hasn't seen"},
                    {"text": "More examples make the computer faster"},
                    {"text": "It doesn't — more data makes it confused"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "What happens if you train AI with only pictures of red apples?",
                "answers": [
                    {"text": "It will recognize all fruits perfectly"},
                    {"text": "It might not recognize green apples because it never saw them"},
                    {"text": "It will become smarter than humans"},
                    {"text": "Nothing — AI doesn't care about colors"},
                ],
                "correct_answer_index": 1,
            },
        ],
    },
    {
        "title": "AI in Everyday Life",
        "description": "You use AI every day without knowing it! Test how much you know.",
        "tags": ["AI", "technology", "real world"],
        "is_verified": True,
        "questions": [
            {
                "text": "Which of these uses AI?",
                "answers": [
                    {"text": "A light switch"},
                    {"text": "YouTube video recommendations"},
                    {"text": "A regular calculator"},
                    {"text": "A paper notebook"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "How does your phone unlock with your face?",
                "answers": [
                    {"text": "It reads your mind"},
                    {"text": "AI compares your face to a stored pattern it learned"},
                    {"text": "The camera just checks if someone is there"},
                    {"text": "It recognizes your clothes"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "What does a spam filter in email use to block junk mail?",
                "answers": [
                    {"text": "It blocks all emails from strangers"},
                    {"text": "AI that learned to recognize spam patterns from millions of examples"},
                    {"text": "A person reads every email first"},
                    {"text": "It only allows emails with pictures"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "Self-driving cars use AI to...",
                "answers": [
                    {"text": "Fly over traffic"},
                    {"text": "See roads, signs, and other cars using cameras and sensors"},
                    {"text": "Follow a pre-drawn line on the road"},
                    {"text": "Listen to the driver's thoughts"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "Can AI have real feelings like being happy or sad?",
                "answers": [
                    {"text": "Yes, all AI has emotions"},
                    {"text": "No — AI can imitate emotions but doesn't actually feel anything"},
                    {"text": "Only the most expensive AI has feelings"},
                    {"text": "Yes, but only when turned off"},
                ],
                "correct_answer_index": 1,
            },
        ],
    },
    {
        "title": "World Geography Challenge",
        "description": "Explore continents, countries, and landmarks around the globe!",
        "tags": ["geography", "world", "countries"],
        "is_verified": False,
        "questions": [
            {
                "text": "How many continents are there on Earth?",
                "answers": [{"text": "5"}, {"text": "6"}, {"text": "7"}, {"text": "8"}],
                "correct_answer_index": 2,
            },
            {
                "text": "Which is the longest river in the world?",
                "answers": [{"text": "Amazon"}, {"text": "Nile"}, {"text": "Mississippi"}, {"text": "Danube"}],
                "correct_answer_index": 1,
            },
            {
                "text": "In which country is the Eiffel Tower?",
                "answers": [{"text": "Italy"}, {"text": "Spain"}, {"text": "England"}, {"text": "France"}],
                "correct_answer_index": 3,
            },
            {
                "text": "What is the largest desert in the world?",
                "answers": [{"text": "Gobi"}, {"text": "Sahara"}, {"text": "Kalahari"}, {"text": "Antarctic"}],
                "correct_answer_index": 3,
            },
        ],
    },
    {
        "title": "Fun with Math",
        "description": "Quick math puzzles to test your brain power!",
        "tags": ["math", "logic", "puzzles"],
        "is_verified": False,
        "questions": [
            {
                "text": "What is 15 + 27?",
                "answers": [{"text": "40"}, {"text": "42"}, {"text": "43"}, {"text": "41"}],
                "correct_answer_index": 1,
            },
            {
                "text": "How many sides does a hexagon have?",
                "answers": [{"text": "5"}, {"text": "6"}, {"text": "7"}, {"text": "8"}],
                "correct_answer_index": 1,
            },
            {
                "text": "What is 9 x 8?",
                "answers": [{"text": "63"}, {"text": "81"}, {"text": "72"}, {"text": "64"}],
                "correct_answer_index": 2,
            },
            {
                "text": "If you have 3 dozen eggs, how many eggs do you have?",
                "answers": [{"text": "30"}, {"text": "33"}, {"text": "36"}, {"text": "39"}],
                "correct_answer_index": 2,
            },
            {
                "text": "What is the next number: 2, 4, 8, 16, ...?",
                "answers": [{"text": "20"}, {"text": "24"}, {"text": "32"}, {"text": "30"}],
                "correct_answer_index": 2,
            },
        ],
    },
    {
        "title": "How Computers Think",
        "description": "Learn the basics of how computers and AI work through fun questions!",
        "tags": ["technology", "AI", "computers"],
        "is_verified": False,
        "questions": [
            {
                "text": "What language do computers understand at the lowest level?",
                "answers": [{"text": "English"}, {"text": "Python"}, {"text": "Binary (0s and 1s)"}, {"text": "Emoji"}],
                "correct_answer_index": 2,
            },
            {
                "text": "What does 'AI' stand for?",
                "answers": [
                    {"text": "Automatic Internet"},
                    {"text": "Artificial Intelligence"},
                    {"text": "Advanced Information"},
                    {"text": "Amazing Invention"},
                ],
                "correct_answer_index": 1,
            },
            {
                "text": "What is a 'pixel'?",
                "answers": [
                    {"text": "A tiny robot"},
                    {"text": "A type of battery"},
                    {"text": "A tiny dot of color on a screen"},
                    {"text": "A computer virus"},
                ],
                "correct_answer_index": 2,
            },
            {
                "text": "How does AI learn to recognize pictures?",
                "answers": [
                    {"text": "It has real eyes"},
                    {"text": "Someone types a description for each picture"},
                    {"text": "It studies thousands of example pictures"},
                    {"text": "It guesses randomly"},
                ],
                "correct_answer_index": 2,
            },
        ],
    },
]


def migrate() -> None:
    with engine.begin() as conn:
        # Check if workshop_missions table exists
        inspector = inspect(engine)
        if "workshop_missions" not in inspector.get_table_names():
            print("[SEED] workshop_missions table does not exist — skipping seed.")
            return

        existing = conn.execute(
            text("SELECT COUNT(*) FROM workshop_missions WHERE title = 'How AI Learns From Data'"),
        ).scalar()
        if existing and existing > 0:
            print("[SEED] Workshop mock missions already seeded — skipping.")
            return

        # Find first user to use as author
        author_row = conn.execute(text("SELECT TOP 1 id FROM users ORDER BY id")).fetchone()
        if not author_row:
            print("[SEED] No users in database — skipping workshop seed.")
            return
        author_id = author_row[0]

        now = datetime.now(timezone.utc).isoformat()

        for m in MISSIONS:
            quiz_json = json.dumps(m["questions"], ensure_ascii=False)
            tags_json = json.dumps(m["tags"], ensure_ascii=False)
            is_verified = 1 if m["is_verified"] else 0
            verified_at = now if m["is_verified"] else None

            if verified_at:
                conn.execute(
                    text(
                        "INSERT INTO workshop_missions "
                        "(title, description, author_id, mission_type, version, tags, "
                        "download_count, is_published, is_verified, verified_at, quiz_data, created_at) "
                        "VALUES (:title, :desc, :author, 'quiz', 1, :tags, "
                        "0, 1, :verified, :verified_at, :quiz, :created)"
                    ),
                    {
                        "title": m["title"],
                        "desc": m["description"],
                        "author": author_id,
                        "tags": tags_json,
                        "verified": is_verified,
                        "verified_at": verified_at,
                        "quiz": quiz_json,
                        "created": now,
                    },
                )
            else:
                conn.execute(
                    text(
                        "INSERT INTO workshop_missions "
                        "(title, description, author_id, mission_type, version, tags, "
                        "download_count, is_published, is_verified, quiz_data, created_at) "
                        "VALUES (:title, :desc, :author, 'quiz', 1, :tags, "
                        "0, 1, :verified, :quiz, :created)"
                    ),
                    {
                        "title": m["title"],
                        "desc": m["description"],
                        "author": author_id,
                        "tags": tags_json,
                        "verified": is_verified,
                        "quiz": quiz_json,
                        "created": now,
                    },
                )

    print(f"[SEED] Inserted {len(MISSIONS)} workshop missions (2 verified).")


if __name__ == "__main__":
    migrate()
