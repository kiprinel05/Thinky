from typing import List, Optional, Union
from pydantic import AnyHttpUrl, validator
from pydantic_settings import BaseSettings, SettingsConfigDict
import secrets
import os

class Settings(BaseSettings):
    # App Settings
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Thinky Backend"
    
    # Security
    SECRET_KEY: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    ALGORITHM: str = "HS256"
    
    # Database (Azure SQL) — DB_* fields must be declared before DATABASE_URL
    # so the validator can read them from `values`.
    DB_USER: Optional[str] = None
    DB_PASSWORD: Optional[str] = None
    DB_HOST: Optional[str] = None
    DB_PORT: str = "1433"
    DB_NAME: Optional[str] = None
    DB_DRIVER: str = "ODBC Driver 18 for SQL Server"
    USE_AZURE_AD: bool = False
    DATABASE_URL: Optional[str] = None
    
    # Supabase (Legacy/Reference)
    SUPABASE_URL: Optional[str] = None
    SUPABASE_ANON_KEY: Optional[str] = None
    
    # ML Models
    MODEL_PATH_SHAPE: str = "ml/artifacts/shape_model.pth"
    MODEL_PATH_COLOR: str = "ml/artifacts/color_model.pth"

    model_config = SettingsConfigDict(
        env_file=".env", 
        case_sensitive=True,
        extra="ignore"
    )

    @validator("SECRET_KEY", pre=True, always=True)
    def validate_secret_key(cls, v: Optional[str]) -> str:
        if not v:
            print("[WARNING] SECRET_KEY not set - generating temporary key")
            return secrets.token_urlsafe(32)
        return v
        
    @validator("DATABASE_URL", pre=True, always=True)
    def assemble_db_connection(cls, v: Optional[str], values: dict) -> str:
        if isinstance(v, str) and v:
            return v
            
        # Fallback to constructing from components
        if all([values.get("DB_USER"), values.get("DB_PASSWORD"), values.get("DB_HOST"), values.get("DB_NAME")]):
            from urllib.parse import quote_plus
            user = values.get("DB_USER")
            password = quote_plus(values.get("DB_PASSWORD"))
            host = values.get("DB_HOST")
            port = values.get("DB_PORT")
            db_name = values.get("DB_NAME")
            driver = quote_plus(values.get("DB_DRIVER"))
            
            return f"mssql+pyodbc://{user}:{password}@{host}:{port}/{db_name}?driver={driver}&Encrypt=yes&TrustServerCertificate=no"
            
        return v

settings = Settings()
