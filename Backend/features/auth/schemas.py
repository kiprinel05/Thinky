from pydantic import BaseModel, EmailStr, field_validator, ConfigDict
from typing import Optional

class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str
    confirm_password: str

    @field_validator('username')
    @classmethod
    def validate_username(cls, v):
        if len(v.strip()) < 3:
            raise ValueError('Username must be at least 3 characters long')
        if len(v.strip()) > 50:
            raise ValueError('Username must be less than 50 characters')
        return v.strip()

    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters long')
        if len(v) > 100:
            raise ValueError('Password must be less than 100 characters')
        return v

    @field_validator('confirm_password')
    @classmethod
    def validate_confirm_password(cls, v, info):
        if 'password' in info.data and v != info.data['password']:
            raise ValueError('Passwords do not match')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class GuestRegister(BaseModel):
    name: str

    @field_validator('name')
    @classmethod
    def validate_name(cls, v):
        if len(v.strip()) < 1:
            raise ValueError('Name cannot be empty')
        if len(v.strip()) > 100:
            raise ValueError('Name must be less than 100 characters')
        return v.strip()

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    username: Optional[str] = None
    email: Optional[str] = None
    is_guest: bool
    guest_name: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    username: Optional[str] = None
    email: Optional[str] = None
    is_guest: bool
    guest_name: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetVerify(BaseModel):
    email: EmailStr
    code: str

    @field_validator('code')
    @classmethod
    def validate_code(cls, v):
        if len(v) != 6 or not v.isdigit():
            raise ValueError('Code must be exactly 6 digits')
        return v

class PasswordResetConfirm(BaseModel):
    email: EmailStr
    code: str
    new_password: str

    @field_validator('code')
    @classmethod
    def validate_code(cls, v):
        if len(v) != 6 or not v.isdigit():
            raise ValueError('Code must be exactly 6 digits')
        return v

    @field_validator('new_password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters long')
        if len(v) > 100:
            raise ValueError('Password must be less than 100 characters')
        return v
