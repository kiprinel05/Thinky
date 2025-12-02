from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import sys
from pathlib import Path
import uuid

sys.path.append(str(Path(__file__).resolve().parent.parent.parent))
from database import get_db
from models.user_model import User
from api.schemas.auth_schemas import (
    UserRegister, 
    UserLogin, 
    GuestRegister, 
    TokenResponse,
    UserResponse
)
from api.auth_utils import (
    get_password_hash, 
    verify_password, 
    create_access_token
)
from datetime import timedelta
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

