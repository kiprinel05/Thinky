from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import traceback

from core.config import settings
from core.database import engine, Base

# Import all models to ensure they are registered with SQLAlchemy Base before creation
from features.auth.models import User, PasswordResetCode
from features.mission.models import Mission, MissionProgress
from features.quiz.models import QuizResult

# Feature Routers
from features.auth.router import router as auth_router
from features.mission.router import router as mission_router
from features.quiz.router import router as quiz_router
from features.color.router import router as color_router
from features.shape.router import router as shape_router
from features.pixy_learns.router import router as pixy_learns_router
from features.drawing.router import router as drawing_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

# Global Exception Handlers
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    print(f"[ERROR] Unhandled exception: {exc}")
    traceback.print_exc()
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error", "error": str(exc)},
        headers={"Access-Control-Allow-Origin": "*"}
    )

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers={"Access-Control-Allow-Origin": "*"}
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()},
        headers={"Access-Control-Allow-Origin": "*"}
    )

# Startup Event
@app.on_event("startup")
def startup_event():
    try:
        # Create tables
        Base.metadata.create_all(bind=engine)
        print("[OK] Database tables verified/created")
    except Exception as e:
        print(f"[WARNING] Database initialization failed: {e}")
        traceback.print_exc()

# Include Routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(mission_router, prefix=settings.API_V1_STR)
app.include_router(quiz_router, prefix=settings.API_V1_STR)
app.include_router(color_router, prefix=settings.API_V1_STR)
app.include_router(shape_router, prefix=settings.API_V1_STR)
app.include_router(pixy_learns_router, prefix=settings.API_V1_STR)
app.include_router(drawing_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {"message": f"{settings.PROJECT_NAME} is running!"}

