from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from config import DATABASE_URL, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME, DB_DRIVER

# Azure SQL Database connection
# Supports both Azure AD authentication and SQL authentication

from config import USE_AZURE_AD

# Connection arguments for Azure SQL
connect_args = {
    "timeout": 10,  # 10 seconds timeout
}

# Handle Azure AD authentication connection string
if USE_AZURE_AD or (DATABASE_URL and "Active Directory" in DATABASE_URL):
    # For Azure AD, connection string is in ADO.NET format
    # Need to convert it to ODBC format for pyodbc
    if DATABASE_URL.startswith("Server="):
        # ADO.NET connection string format
        # Convert ADO.NET format to ODBC format
        import re
        import pyodbc
        
        # Get available ODBC drivers
        available_drivers = pyodbc.drivers()
        if "ODBC Driver 18 for SQL Server" in available_drivers:
            driver = "ODBC Driver 18 for SQL Server"
        elif "ODBC Driver 17 for SQL Server" in available_drivers:
            driver = "ODBC Driver 17 for SQL Server"
        else:
            driver = "ODBC Driver 17 for SQL Server"  # Default
        
        # Convert ADO.NET format to ODBC format
        # Replace Server= with Server=
        # Replace Initial Catalog= with Database=
        # Convert Encrypt=True to Encrypt=yes
        # Convert TrustServerCertificate=False to TrustServerCertificate=no
        # Add Driver if not present
        
        conn_str = DATABASE_URL
        
        # Replace ADO.NET specific attributes
        conn_str = conn_str.replace("Initial Catalog=", "Database=")
        conn_str = conn_str.replace("Encrypt=True", "Encrypt=yes")
        conn_str = conn_str.replace("Encrypt=False", "Encrypt=no")
        conn_str = conn_str.replace("TrustServerCertificate=True", "TrustServerCertificate=yes")
        conn_str = conn_str.replace("TrustServerCertificate=False", "TrustServerCertificate=no")
        
        # For Azure AD authentication, we need to handle it separately
        # Extract server and database info for SQL authentication fallback
        # If Azure AD is specified but we don't have SQL credentials, show helpful error
        if 'Authentication' in DATABASE_URL and not all([DB_USER, DB_PASSWORD]):
            print("[WARNING] Azure AD authentication requires additional setup.")
            print("[INFO] For now, using connection string without Authentication attribute.")
            print("[INFO] Consider using SQL authentication with user/password in .env")
        
        # Remove Authentication attribute - will use SQL auth if credentials provided
        conn_str = re.sub(r'Authentication="[^"]*";?', '', conn_str)
        conn_str = re.sub(r'Authentication=[^;]*;?', '', conn_str)
        
        # If we have SQL credentials, add them to connection string
        if all([DB_USER, DB_PASSWORD]):
            # Add UID and PWD to connection string (only if not already present)
            if "UID=" not in conn_str and "User ID=" not in conn_str:
                # Ensure semicolon at end before adding
                if not conn_str.endswith(";"):
                    conn_str = f"{conn_str};"
                conn_str = f"{conn_str}UID={DB_USER};PWD={DB_PASSWORD};"
        
        # Add Driver if not present
        if "Driver=" not in conn_str:
            if conn_str.endswith(";"):
                conn_str = f"{conn_str}Driver={{{driver}}};"
            else:
                conn_str = f"{conn_str};Driver={{{driver}}};"
        
        # Convert to pyodbc connection string format for SQLAlchemy
        from urllib.parse import quote_plus
        # URL encode the connection string
        encoded_conn_str = quote_plus(conn_str)
        # SQLAlchemy format: mssql+pyodbc:///?odbc_connect=<encoded_connection_string>
        connection_string = f"mssql+pyodbc:///?odbc_connect={encoded_conn_str}"
    else:
        connection_string = DATABASE_URL
elif all([DB_USER, DB_PASSWORD, DB_HOST, DB_NAME]):
    # SQL authentication with individual parameters
    from urllib.parse import quote_plus
    from config import DB_DRIVER
    encoded_password = quote_plus(DB_PASSWORD)
    encoded_driver = quote_plus(DB_DRIVER)
    # Azure SQL connection string format
    connection_string = f"mssql+pyodbc://{DB_USER}:{encoded_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}?driver={encoded_driver}&Encrypt=yes&TrustServerCertificate=no"
else:
    connection_string = DATABASE_URL

engine = create_engine(
    connection_string,
    pool_pre_ping=True,  # Verify connections before using them
    pool_size=5,  # Connection pool size
    max_overflow=10,  # Maximum overflow connections
    connect_args=connect_args,
    echo=False  # Set to True for SQL debugging
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    try:
        Base.metadata.create_all(bind=engine)
        print("[OK] Database connection successful and tables initialized")
    except Exception as e:
        print(f"[WARNING] Database connection failed: {e}")
        print("[INFO] Application will continue but database operations may fail")
        print("[INFO] Please check your .env file and database connection settings")

