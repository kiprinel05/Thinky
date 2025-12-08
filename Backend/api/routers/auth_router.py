from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import sys
from pathlib import Path
import uuid
import random
from datetime import datetime, timedelta, timezone

sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from database import get_db
from models.user_model import User
from models.password_reset_model import PasswordResetCode
from api.schemas.auth_schemas import (
    UserRegister, 
    UserLogin, 
    GuestRegister, 
    TokenResponse,
    UserResponse,
    PasswordResetRequest,
    PasswordResetVerify,
    PasswordResetConfirm
)
from api.auth_utils import (
    get_password_hash, 
    verify_password, 
    create_access_token
)
from api.services.email_service import email_service
from config import ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    existing_username = db.query(User).filter(User.username == user_data.username).first()
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    hashed_password = get_password_hash(user_data.password)
    new_user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hashed_password,
        is_guest=False
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(new_user.id), "email": new_user.email},
        expires_delta=access_token_expires
    )
    
    return TokenResponse(
        access_token=access_token,
        user_id=new_user.id,
        username=new_user.username,
        email=new_user.email,
        is_guest=False
    )

@router.post("/login", response_model=TokenResponse)
async def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == credentials.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if user.is_guest:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Guest users cannot login with email/password"
        )
    
    if not user.hashed_password or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
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

@router.post("/guest", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_guest(guest_data: GuestRegister, db: Session = Depends(get_db)):
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
    
    db.add(new_guest)
    db.commit()
    db.refresh(new_guest)
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
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

@router.get("/me", response_model=UserResponse)
async def get_current_user(
    token: str = Depends(lambda: None),  # TODO: Implement proper token extraction from header
    db: Session = Depends(get_db)
):
    # TODO: Implement proper JWT token extraction and validation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Endpoint not yet implemented"
    )

@router.post("/forgot-password/request")
async def request_password_reset(
    request: PasswordResetRequest,
    db: Session = Depends(get_db)
):
    """
    Request password reset - sends a 6-digit code to the user's email.
    """
    try:
        user = db.query(User).filter(User.email == request.email).first()
        
        # For security, don't reveal if email exists or not
        # Always return success message
        if not user:
            return {"message": "If the email exists, a reset code has been sent."}
        
        if user.is_guest:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Guest users cannot reset password"
            )
        
        # Generate 6-digit code
        code = f"{random.randint(100000, 999999)}"
        
        # Expires in 10 minutes
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=10)
        
        # Invalidate any existing unused codes for this user
        try:
            existing_codes = db.query(PasswordResetCode).filter(
                PasswordResetCode.user_id == user.id,
                PasswordResetCode.is_used == 0,
                PasswordResetCode.expires_at > datetime.now(timezone.utc)
            ).all()
            
            for existing_code in existing_codes:
                existing_code.is_used = 1
        except Exception as e:
            print(f"[WARNING] Error invalidating existing codes: {e}")
            # Continue anyway - not critical
        
        # Create new reset code
        reset_code = PasswordResetCode(
            user_id=user.id,
            code=code,
            email=user.email,
            expires_at=expires_at,
            is_used=0
        )
        
        db.add(reset_code)
        db.commit()
        
        # Send email
        email_service.send_password_reset_code(user.email, code)
        
        return {"message": "If the email exists, a reset code has been sent."}
    except HTTPException:
        raise
    except Exception as e:
        print(f"[ERROR] Error in request_password_reset: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal server error: {str(e)}"
        )

@router.post("/forgot-password/verify")
async def verify_reset_code(
    request: PasswordResetVerify,
    db: Session = Depends(get_db)
):
    """
    Verify the reset code before allowing password reset.
    """
    user = db.query(User).filter(User.email == request.email).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Find valid reset code
    reset_code = db.query(PasswordResetCode).filter(
        PasswordResetCode.user_id == user.id,
        PasswordResetCode.code == request.code,
        PasswordResetCode.is_used == 0,
        PasswordResetCode.expires_at > datetime.now(timezone.utc)
    ).first()
    
    if not reset_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired code"
        )
    
    return {"message": "Code verified successfully", "valid": True}

@router.post("/forgot-password/reset")
async def reset_password(
    request: PasswordResetConfirm,
    db: Session = Depends(get_db)
):
    """
    Reset password using verified code.
    """
    user = db.query(User).filter(User.email == request.email).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.is_guest:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Guest users cannot reset password"
        )
    
    # Find and verify reset code
    reset_code = db.query(PasswordResetCode).filter(
        PasswordResetCode.user_id == user.id,
        PasswordResetCode.code == request.code,
        PasswordResetCode.is_used == 0,
        PasswordResetCode.expires_at > datetime.now(timezone.utc)
    ).first()
    
    if not reset_code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired code"
        )
    
    # Mark code as used
    reset_code.is_used = 1
    
    # Update password
    user.hashed_password = get_password_hash(request.new_password)
    
    db.commit()
    
    return {"message": "Password reset successfully"}

