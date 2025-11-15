from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class Mission(Base):
    __tablename__ = "missions"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    mission_path = Column(String, unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    order_index = Column(Integer, nullable=False, default=0)
    background_color = Column(String, nullable=True)  # Hex color
    height = Column(Float, nullable=True, default=200.0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    progress = relationship("MissionProgress", back_populates="mission", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Mission(id={self.id}, title={self.title}, mission_path={self.mission_path})>"

class MissionProgress(Base):
    __tablename__ = "mission_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    mission_id = Column(Integer, ForeignKey("missions.id"), nullable=False, index=True)
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    score = Column(Float, nullable=True)  # Optional score for the mission
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    mission = relationship("Mission", back_populates="progress")

    def __repr__(self):
        return f"<MissionProgress(id={self.id}, user_id={self.user_id}, mission_id={self.mission_id}, is_completed={self.is_completed})>"

class QuizResult(Base):
    __tablename__ = "quiz_results"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    quiz_type = Column(String, nullable=False, default="introduction")  # e.g., "introduction", "assessment"
    score = Column(Integer, nullable=False)
    total_questions = Column(Integer, nullable=False)
    percentage = Column(Float, nullable=False)
    correct_answers = Column(Integer, nullable=False)
    incorrect_answers = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<QuizResult(id={self.id}, user_id={self.user_id}, score={self.score}/{self.total_questions}, percentage={self.percentage})>"

