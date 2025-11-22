"""
Script to disable Geometric Shapes mission
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))
from models.user_model import User
from models.mission_model import Mission, MissionProgress, QuizResult
from database import SessionLocal, init_db

def disable_geometric_shapes():
    """Disable Geometric Shapes mission"""
    init_db()
    db = SessionLocal()
    
    try:
        mission = db.query(Mission).filter(
            Mission.mission_path == "geometric_shapes"
        ).first()
        
        if mission:
            mission.is_active = False
            db.commit()
            print(f"Mission 'Geometric Shapes' has been disabled.")
        else:
            print("Mission 'Geometric Shapes' not found in database.")
        
    except Exception as e:
        print(f"Error disabling mission: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    disable_geometric_shapes()



