from pathlib import Path
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

BASE_DIR = Path(__file__).resolve().parent

MODEL_PATHS = {
    "shape": BASE_DIR / "models" / "shape_model" / "saved_model.pth",
    "color": BASE_DIR / "models" / "color_model" / "saved_model.pth",
}

CLASSES = {
    "shape": ["Circle", "Square", "Triangle"],
    "color": ["red", "green", "blue", "yellow", "orange", "purple", "pink", "brown", "black", "white"]
}

# Database Configuration (Azure SQL Database)
# Support for both Azure AD authentication and SQL authentication

# Option 1: Full connection string (recommended for Azure AD)
# Azure provides connection strings with Active Directory authentication
DATABASE_URL = os.getenv("DATABASE_URL") or os.getenv("AZURE_DATABASE_URL", "")

# Option 2: Individual environment variables (for SQL authentication)
DB_USER = os.getenv("user") or os.getenv("DB_USER") or os.getenv("AZURE_DB_USER")
DB_PASSWORD = os.getenv("password") or os.getenv("DB_PASSWORD") or os.getenv("AZURE_DB_PASSWORD")
DB_HOST = os.getenv("host") or os.getenv("DB_HOST") or os.getenv("AZURE_DB_HOST")
DB_PORT = os.getenv("port") or os.getenv("DB_PORT") or os.getenv("AZURE_DB_PORT", "1433")
DB_NAME = os.getenv("dbname") or os.getenv("DB_NAME") or os.getenv("AZURE_DB_NAME")
DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")

# Check if using Azure AD authentication (from connection string)
USE_AZURE_AD = os.getenv("USE_AZURE_AD", "false").lower() == "true" or "Active Directory" in (DATABASE_URL or "")

# Construct DATABASE_URL from individual variables if not provided (SQL auth only)
if not DATABASE_URL and all([DB_USER, DB_PASSWORD, DB_HOST, DB_NAME]):
    # URL encode password and driver for Azure SQL connection string
    from urllib.parse import quote_plus
    encoded_password = quote_plus(DB_PASSWORD)
    encoded_driver = quote_plus(DB_DRIVER)
    # Azure SQL connection string format: mssql+pyodbc://user:pass@host:port/db?driver=...
    DATABASE_URL = f"mssql+pyodbc://{DB_USER}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}?driver={encoded_driver}&Encrypt=yes&TrustServerCertificate=no"
elif not DATABASE_URL:
    raise ValueError(
        "Database configuration missing! Please set either:\n"
        "  - DATABASE_URL (full connection string with Azure AD or SQL auth), OR\n"
        "  - Individual variables: user, password, host, port, dbname (for SQL auth only)"
    )

# JWT Settings
# SECRET_KEY is used to sign and verify JWT tokens
# If not set in .env, a secure random key will be generated (not recommended for production)
import secrets

_secret_key_from_env = os.getenv("SECRET_KEY")
if _secret_key_from_env:
    SECRET_KEY = _secret_key_from_env
else:
    # Generate a secure random key if not provided
    # WARNING: This will change on each restart if not set in .env
    # For production, always set SECRET_KEY in .env or environment variables
    SECRET_KEY = secrets.token_urlsafe(32)
    print("[WARNING] SECRET_KEY not set in .env - using auto-generated key")
    print("[WARNING] This key will change on restart. Set SECRET_KEY in .env for production!")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

# Supabase API Configuration (for reference/future use)
# These are the Supabase project credentials
SUPABASE_URL = os.getenv("SUPABASE_URL", "https://etdtlmdwqywnhqbjsoja.supabase.co")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "sb_publishable_rG1PNy-j7nNk5JDbWUXyug_7vASf3Y2")