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
from features.workshop.models import WorkshopMission, WorkshopDownload
from features.leaderboard import models as leaderboard_models  # noqa: F401

# Feature Routers
from features.auth.router import router as auth_router
from features.mission.router import router as mission_router
from features.quiz.router import router as quiz_router
from features.color.router import router as color_router
from features.shape.router import router as shape_router
from features.pixy_learns.router import router as pixy_learns_router
from features.drawing.router import router as drawing_router
from features.numbers.router import router as numbers_router
from features.workshop.router import router as workshop_router
from features.animals.router import router as animals_router
from features.grouping.router import router as grouping_router
from features.vocabulary.router import router as vocabulary_router
from features.mascot.router import router as mascot_router
from features.describe.router import router as describe_router
from features.pattern.router import router as pattern_router
from features.xp.router import router as xp_router
from features.leaderboard.router import router as leaderboard_router

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
        Base.metadata.create_all(bind=engine)
        print("[OK] Database tables verified/created")
    except Exception as e:
        print(f"[WARNING] Database initialization failed: {e}")
        traceback.print_exc()

    try:
        from migrations.add_xp_earned_to_quiz_results import migrate as migrate_xp
        migrate_xp()
    except Exception as e:
        print(f"[WARNING] XP migration skipped: {e}")

    try:
        from migrations.add_is_admin_to_users import migrate as migrate_admin
        migrate_admin()
    except Exception as e:
        print(f"[WARNING] is_admin migration skipped: {e}")

    try:
        from migrations.add_workshop_verified_columns import migrate as migrate_workshop
        migrate_workshop()
    except Exception as e:
        print(f"[WARNING] Workshop verified columns migration skipped: {e}")

    try:
        from migrations.seed_workshop_missions import migrate as seed_workshop
        seed_workshop()
    except Exception as e:
        print(f"[WARNING] Workshop seed skipped: {e}")

# Include Routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(mission_router, prefix=settings.API_V1_STR)
app.include_router(quiz_router, prefix=settings.API_V1_STR)
app.include_router(color_router, prefix=settings.API_V1_STR)
app.include_router(shape_router, prefix=settings.API_V1_STR)
app.include_router(pixy_learns_router, prefix=settings.API_V1_STR)
app.include_router(drawing_router, prefix=settings.API_V1_STR)
app.include_router(numbers_router, prefix=settings.API_V1_STR)
app.include_router(workshop_router, prefix=settings.API_V1_STR)
app.include_router(animals_router, prefix=settings.API_V1_STR)
app.include_router(grouping_router, prefix=settings.API_V1_STR)
app.include_router(vocabulary_router, prefix=settings.API_V1_STR)
app.include_router(mascot_router, prefix=settings.API_V1_STR)
app.include_router(describe_router, prefix=settings.API_V1_STR)
app.include_router(pattern_router, prefix=settings.API_V1_STR)
app.include_router(xp_router, prefix=settings.API_V1_STR)
app.include_router(leaderboard_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {"message": f"{settings.PROJECT_NAME} is running!"}

