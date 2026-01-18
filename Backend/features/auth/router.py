from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from core.database import get_db
from features.auth.schemas import (
    UserRegister, UserLogin, GuestRegister, TokenResponse, 
    UserResponse, PasswordResetRequest, PasswordResetVerify, PasswordResetConfirm
)
from features.auth.service import AuthService
from features.auth.repository import AuthRepository
from core.config import settings
from core.security import create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

def get_auth_service(db: Session = Depends(get_db)) -> AuthService:
    repository = AuthRepository(model=None, db=db) # model not strictly needed for init if not used in Base __init__ logic immediately or if overridden
    # BaseRepository expects model class.
    # We should fix BaseRepository init or pass generic model.
    # Providing the User model class here.
    from features.auth.models import User
    repository.model = User
    return AuthService(repository)

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, service: AuthService = Depends(get_auth_service)):
    try:
        user = service.register(user_data)
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        return TokenResponse(
            access_token=access_token,
            user_id=user.id,
            username=user.username,
            email=user.email,
            is_guest=False
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, service: AuthService = Depends(get_auth_service)):
    token = service.login(credentials)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    return token

@router.post("/guest", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_guest(guest_data: GuestRegister, service: AuthService = Depends(get_auth_service)):
    return service.register_guest(guest_data)

@router.post("/forgot-password/request")
async def request_password_reset(request: PasswordResetRequest, service: AuthService = Depends(get_auth_service)):
    try:
        msg = service.request_password_reset(request.email)
        return {"message": msg}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

@router.post("/forgot-password/verify")
async def verify_reset_code(request: PasswordResetVerify, service: AuthService = Depends(get_auth_service)):
    is_valid = service.verify_reset_code(request.email, request.code)
    if not is_valid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired code")
    return {"message": "Code verified successfully", "valid": True}

@router.post("/forgot-password/reset")
async def reset_password(request: PasswordResetConfirm, service: AuthService = Depends(get_auth_service)):
    try:
        service.reset_password(request.email, request.code, request.new_password)
        return {"message": "Password reset successfully"}
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
