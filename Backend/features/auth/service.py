from typing import Optional
from datetime import timedelta
import uuid
import random

from core.base.service import BaseService
from core.security import get_password_hash, verify_password, create_access_token
from features.auth.models import User, PasswordResetCode
from features.auth.schemas import UserRegister, UserLogin, GuestRegister, TokenResponse, PasswordResetRequest, PasswordResetConfirm
from features.auth.repository import AuthRepository
from core.config import settings
from api.services.email_service import email_service  # We'll need to refactor email service later, but importing for now

class AuthService(BaseService[User, UserRegister, UserLogin]):
    def __init__(self, repository: AuthRepository):
        super().__init__(repository)
        self.repository = repository

    def register(self, user_data: UserRegister) -> User:
        if self.repository.get_by_email(user_data.email):
            raise ValueError("Email already registered")
        
        if self.repository.get_by_username(user_data.username):
            raise ValueError("Username already taken")
            
        hashed_password = get_password_hash(user_data.password)
        new_user = User(
            username=user_data.username,
            email=user_data.email,
            hashed_password=hashed_password,
            is_guest=False
        )
        # We manually add it because create() expects SchemaType but we composed the User object manually
        # OR we can just use repository.create if we map schemas effectively.
        # simpler here to use db directly via repository helper or access db
        self.repository.db.add(new_user)
        self.repository.db.commit()
        self.repository.db.refresh(new_user)
        return new_user

    def login(self, credentials: UserLogin) -> Optional[TokenResponse]:
        user = self.repository.get_by_email(credentials.email)
        if not user or user.is_guest:
            return None
        
        if not user.hashed_password or not verify_password(credentials.password, user.hashed_password):
            return None
            
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=access_token_expires
        )
        
        return TokenResponse(
            access_token=access_token,
            user_id=user.id,
            username=user.username,
            email=user.email,
            is_guest=False
        )

    def register_guest(self, guest_data: GuestRegister) -> TokenResponse:
        unique_suffix = uuid.uuid4().hex
        generated_username = f"guest_{unique_suffix[:8]}"
        generated_email = f"{generated_username}@thinky.local"

        new_guest = User(
            guest_name=guest_data.name,
            is_guest=True,
            username=generated_username,
            email=generated_email,
            hashed_password=None
        )
        
        self.repository.db.add(new_guest)
        self.repository.db.commit()
        self.repository.db.refresh(new_guest)
        
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(new_guest.id), "is_guest": True},
            expires_delta=access_token_expires
        )
        
        return TokenResponse(
            access_token=access_token,
            user_id=new_guest.id,
            guest_name=new_guest.guest_name,
            is_guest=True
        )

    def request_password_reset(self, email: str) -> str:
        user = self.repository.get_by_email(email)
        if not user:
             return "If the email exists, a reset code has been sent."
        
        if user.is_guest:
             raise ValueError("Guest users cannot reset password")

        # Invalidate old codes
        self.repository.invalidate_existing_codes(user.id)
        
        # Generate code
        code = f"{random.randint(100000, 999999)}"
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)
        
        reset_code = PasswordResetCode(
            user_id=user.id,
            code=code,
            email=user.email,
            expires_at=expires_at,
            is_used=0
        )
        self.repository.create_reset_code(reset_code)
        
        # Send email (assuming existing service works)
        # in real refactor we should inject email service
        email_service.send_password_reset_code(user.email, code)
        
        return "If the email exists, a reset code has been sent."

    def verify_reset_code(self, email: str, code: str) -> bool:
        user = self.repository.get_by_email(email)
        if not user:
            return False
            
        reset_code = self.repository.get_valid_reset_code(user.id, code)
        return reset_code is not None

    def reset_password(self, email: str, code: str, new_password: str):
        user = self.repository.get_by_email(email)
        if not user or user.is_guest:
            raise ValueError("Invalid user")
            
        reset_code = self.repository.get_valid_reset_code(user.id, code)
        if not reset_code:
            raise ValueError("Invalid or expired code")
            
        reset_code.is_used = 1
        user.hashed_password = get_password_hash(new_password)
        self.repository.db.commit()
