from typing import Optional, List
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from core.base.repository import BaseRepository
from features.auth.models import User, PasswordResetCode
from features.auth.schemas import UserRegister, UserLogin

class AuthRepository(BaseRepository[User, UserRegister, UserLogin]):
    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_by_username(self, username: str) -> Optional[User]:
        return self.db.query(User).filter(User.username == username).first()

    def create_reset_code(self, code: PasswordResetCode) -> PasswordResetCode:
        self.db.add(code)
        self.db.commit()
        self.db.refresh(code)
        return code

    def get_valid_reset_code(self, user_id: int, code: str) -> Optional[PasswordResetCode]:
        return self.db.query(PasswordResetCode).filter(
            PasswordResetCode.user_id == user_id,
            PasswordResetCode.code == code,
            PasswordResetCode.is_used == 0,
            PasswordResetCode.expires_at > datetime.now(timezone.utc)
        ).first()
    
    def invalidate_existing_codes(self, user_id: int):
        existing_codes = self.db.query(PasswordResetCode).filter(
            PasswordResetCode.user_id == user_id,
            PasswordResetCode.is_used == 0,
            PasswordResetCode.expires_at > datetime.now(timezone.utc)
        ).all()
        
        for existing_code in existing_codes:
            existing_code.is_used = 1
        
        if existing_codes:
            self.db.commit()
