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
                "title": "How does Pixy learn?",
                "mission_path": "pixy_learns",
                "description": "Explain how AI models learn from examples",
                "order_index": 1,
                "background_color": "#FF6B6B",
                "height": 200.0,
                "is_active": True
            },
        ]
        
        added_count = 0
        for mission_data in missions_data:
            # Check if mission with this path already exists
            existing = db.query(Mission).filter(
                Mission.mission_path == mission_data["mission_path"]
            ).first()
            
            if not existing:
                mission = Mission(**mission_data)
                db.add(mission)
                added_count += 1
                print(f"Added mission: {mission_data['title']}")
            else:
                print(f"Mission '{mission_data['title']}' already exists. Skipping...")
        
        db.commit()
        if added_count > 0:
            print(f"Successfully added {added_count} new mission(s)!")
        else:
            print("All missions already exist in database.")
        
    except Exception as e:
        print(f"Error initializing missions: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_missions()

