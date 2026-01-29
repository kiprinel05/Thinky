from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from api.utils import init_models
from database import init_db
# Import all models to ensure they are registered with SQLAlchemy Base before init_db()
from models.user_model import User
from models.mission_model import Mission, MissionProgress, QuizResult
from models.password_reset_model import PasswordResetCode
import traceback

app = FastAPI(title="Thinky Classification API")

# CORS configuration for Flutter web
# Allow all origins for development (Flutter web runs on different ports)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

# Global exception handler to ensure CORS headers are always present
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all exceptions and ensure CORS headers are present"""
    print(f"[ERROR] Unhandled exception: {exc}")
    traceback.print_exc()
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error", "error": str(exc)},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD",
            "Access-Control-Allow-Headers": "*",
        }
    )

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Handle HTTP exceptions with CORS headers"""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD",
            "Access-Control-Allow-Headers": "*",
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors with CORS headers"""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors()},
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD",
            "Access-Control-Allow-Headers": "*",
        }
    )

@app.on_event("startup")
def startup_event():
    try:
        init_db()
        # Ensure password_reset_codes table exists
        try:
            from database import engine
            PasswordResetCode.__table__.create(bind=engine, checkfirst=True)
            print("[OK] Password reset codes table verified")
        except Exception as e:
            print(f"[WARNING] Could not verify password_reset_codes table: {e}")
    except Exception as e:
        print(f"[WARNING] Database initialization failed: {e}")
        print("[INFO] Application will start but database features may not work")
        import traceback
        traceback.print_exc()
    
    try:
        init_models()
    except Exception as e:
        print(f"[WARNING] Model initialization failed: {e}")
        print("[INFO] Application will start but ML features may not work")

# Import routers - handle import errors gracefully
try:
    from api.routers import auth_router
    app.include_router(auth_router.router, prefix="/api/v1")
except Exception as e:
    print(f"Warning: Could not load auth_router: {e}")

try:
    from api.routers import shape_router
    app.include_router(shape_router.router, prefix="/api/v1")
except Exception as e:
    print(f"Warning: Could not load shape_router: {e}")

try:
    from api.routers import color_router
    app.include_router(color_router.router, prefix="/api/v1")
except Exception as e:
    print(f"Warning: Could not load color_router: {e}")

try:
    from api.routers import quiz_router
    app.include_router(quiz_router.router, prefix="/api/v1")
except Exception as e:
    print(f"Warning: Could not load quiz_router: {e}")

try:
    from api.routers import mission_router
    app.include_router(mission_router.router, prefix="/api/v1")
except Exception as e:
    print(f"Warning: Could not load mission_router: {e}")

try:
    from api.routers import pixy_learns_router
    app.include_router(pixy_learns_router.router, prefix="/api/v1")
    print("[OK] pixy_learns_router loaded successfully")
except Exception as e:
    print(f"[ERROR] Error loading pixy_learns_router: {e}")
    import traceback
    traceback.print_exc()

@app.options("/{full_path:path}")
async def options_handler(full_path: str):
    """Handle CORS preflight requests"""
    return {"message": "OK"}

@app.get("/")
def root():
    return {"message": "Thinky API is running with Shape + Color Models + Authentication + Quiz + Missions!"}

@app.get("/test-routes")
def test_routes():
    """Test endpoint to verify all routes are registered"""
    routes = []
    for route in app.routes:
        if hasattr(route, 'path') and hasattr(route, 'methods'):
            routes.append({
                "path": route.path,
                "methods": list(route.methods)
            })
    return {"routes": routes, "total": len(routes)}
