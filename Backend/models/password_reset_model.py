from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from database import Base

class PasswordResetCode(Base):
    __tablename__ = "password_reset_codes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    code = Column(String(6), nullable=False, index=True)
    email = Column(String(255), nullable=False)
    is_used = Column(Integer, default=0)  # 0 = not used, 1 = used
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    def __repr__(self):
        return f"<PasswordResetCode(id={self.id}, user_id={self.user_id}, code={self.code}, is_used={self.is_used})>"

