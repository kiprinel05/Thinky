"""
Script pentru adăugarea misiunii 'Draw Shapes' în baza de date.
Rulează: python add_draw_shapes_mission.py
"""
import pyodbc
from dotenv import load_dotenv
import os

load_dotenv()

# Database connection
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT", "1433")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")

connection_string = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={DB_HOST},{DB_PORT};"
    f"DATABASE={DB_NAME};"
    f"UID={DB_USER};"
    f"PWD={DB_PASSWORD};"
)

def add_draw_shapes_mission():
    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()
        
        # Check if mission already exists
        cursor.execute("SELECT id FROM missions WHERE mission_path = ?", ('draw_shapes',))
        existing = cursor.fetchone()
        
        if existing:
            print(f"Mission 'draw_shapes' already exists with ID: {existing[0]}")
            return
        
        # Insert new mission
        cursor.execute("""
            INSERT INTO missions (title, mission_path, description, order_index, background_color, height, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            'Draw Shapes',
            'draw_shapes',
            '3 rounds: draw a triangle, a circle, and a square!',
            3,  # Adjust order_index based on your existing missions
            '#8E97FD',
            200.0,
            1
        ))
        
        conn.commit()
        
        # Get the inserted ID
        cursor.execute("SELECT id FROM missions WHERE mission_path = ?", ('draw_shapes',))
        new_id = cursor.fetchone()[0]
        
        print(f"✅ Mission 'Draw Shapes' added successfully!")
        print(f"   ID: {new_id}")
        print(f"   Path: draw_shapes")
        print(f"   Order: 3")
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error adding mission: {e}")

if __name__ == "__main__":
    add_draw_shapes_mission()
