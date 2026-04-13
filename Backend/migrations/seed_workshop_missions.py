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
        "title": "Solar System Explorer",
        "description": "Test your knowledge about the planets, the Sun, and our solar system!",
        "tags": ["science", "space", "planets"],
        "is_verified": True,
        "questions": [
            {
                "text": "Which planet is closest to the Sun?",
                "answers": [{"text": "Venus"}, {"text": "Mercury"}, {"text": "Earth"}, {"text": "Mars"}],
                "correct_answer_index": 1,
            },
            {
                "text": "What is the largest planet in our solar system?",
                "answers": [{"text": "Saturn"}, {"text": "Neptune"}, {"text": "Jupiter"}, {"text": "Uranus"}],
                "correct_answer_index": 2,
            },
            {
                "text": "How many planets are in our solar system?",
                "answers": [{"text": "7"}, {"text": "8"}, {"text": "9"}, {"text": "10"}],
                "correct_answer_index": 1,
            },
            {
                "text": "Which planet is known as the Red Planet?",
                "answers": [{"text": "Jupiter"}, {"text": "Mars"}, {"text": "Venus"}, {"text": "Saturn"}],
                "correct_answer_index": 1,
            },
            {
                "text": "What gives the Sun its energy?",
                "answers": [
                    {"text": "Burning gas like a campfire"},
                    {"text": "Electricity from space"},
                    {"text": "Nuclear fusion of hydrogen"},
                    {"text": "Batteries inside it"},
                ],
                "correct_answer_index": 2,
            },
        ],
    },
    {
        "title": "Amazing Animals",
        "description": "How much do you know about the animal kingdom? Find out!",
        "tags": ["animals", "nature", "biology"],
        "is_verified": True,
        "questions": [
            {
                "text": "Which animal is the tallest in the world?",
                "answers": [{"text": "Elephant"}, {"text": "Giraffe"}, {"text": "Horse"}, {"text": "Camel"}],
                "correct_answer_index": 1,
            },
            {
                "text": "What do you call a group of fish?",
                "answers": [{"text": "A herd"}, {"text": "A flock"}, {"text": "A school"}, {"text": "A pack"}],
                "correct_answer_index": 2,
            },
            {
                "text": "Which animal can change its color to blend in?",
                "answers": [{"text": "Parrot"}, {"text": "Chameleon"}, {"text": "Goldfish"}, {"text": "Penguin"}],
                "correct_answer_index": 1,
            },
            {
                "text": "How many legs does a spider have?",
                "answers": [{"text": "6"}, {"text": "10"}, {"text": "8"}, {"text": "4"}],
                "correct_answer_index": 2,
            },
            {
                "text": "Which ocean animal is the largest?",
                "answers": [{"text": "Great white shark"}, {"text": "Blue whale"}, {"text": "Giant squid"}, {"text": "Orca"}],
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
            text("SELECT COUNT(*) FROM workshop_missions WHERE title = :t"),
            {"t": MISSIONS[0]["title"]},
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
