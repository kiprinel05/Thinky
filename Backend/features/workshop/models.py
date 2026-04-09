from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

# Support both old (api/) and new (features/) architecture
try:
    from database import Base
except ImportError:
    from core.database import Base


class WorkshopMission(Base):
    __tablename__ = "workshop_missions"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    mission_type = Column(String(50), default="quiz", nullable=False)
    version = Column(Integer, default=1, nullable=False)
    tags = Column(Text, nullable=True)  # JSON array stored as string, e.g. '["geography","science"]'
    download_count = Column(Integer, default=0, nullable=False)
    is_published = Column(Boolean, default=True, nullable=False)
    # Curator / admin: mission reviewed as child-appropriate for the catalog
    is_verified = Column(Boolean, default=False, nullable=False)
    verified_at = Column(DateTime(timezone=True), nullable=True)
    quiz_data = Column(Text, nullable=False)  # JSON string with questions/answers
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    author = relationship("User", backref="workshop_missions")
    downloads = relationship("WorkshopDownload", back_populates="mission", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<WorkshopMission(id={self.id}, title={self.title}, author_id={self.author_id})>"


class WorkshopDownload(Base):
    __tablename__ = "workshop_downloads"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    mission_id = Column(Integer, ForeignKey("workshop_missions.id"), nullable=False, index=True)
    downloaded_at = Column(DateTime(timezone=True), server_default=func.now())

    mission = relationship("WorkshopMission", back_populates="downloads")

    def __repr__(self):
        return f"<WorkshopDownload(id={self.id}, user_id={self.user_id}, mission_id={self.mission_id})>"
