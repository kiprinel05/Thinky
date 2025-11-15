"""
Script to initialize missions in the database
Run this once to populate the missions table
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))
# Import all models to ensure they are registered with SQLAlchemy Base
from models.user_model import User
from models.mission_model import Mission, MissionProgress, QuizResult
from database import SessionLocal, init_db

def init_missions():
    """Initialize default missions"""
    init_db()
    db = SessionLocal()
    
    try:
        # Check if missions already exist
        existing = db.query(Mission).first()
        if existing:
            print("Missions already initialized. Skipping...")
            return
        
        missions_data = [
            {
                "title": "Introduction Quiz",
                "mission_path": "quiz",
                "description": "Let's see what you know about AI!",
                "order_index": 0,
                "background_color": "#8E97FD",
                "height": 220.0,
                "is_active": True
            },
            {
                "title": "Geometric Shapes",
                "mission_path": "geometric_shapes",
                "description": "Learn to recognize geometric shapes",
                "order_index": 1,
                "background_color": "#9B59B6",
                "height": 200.0,
                "is_active": True
            },
        ]
        
        for mission_data in missions_data:
            mission = Mission(**mission_data)
            db.add(mission)
        
        db.commit()
        print(f"Successfully initialized {len(missions_data)} missions!")
        
    except Exception as e:
        print(f"Error initializing missions: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_missions()

