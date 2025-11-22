from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.utils import init_models
from database import init_db
# Import all models to ensure they are registered with SQLAlchemy Base before init_db()
from models.user_model import User
from models.mission_model import Mission, MissionProgress, QuizResult

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

@app.on_event("startup")
def startup_event():
    try:
        init_db()
    except Exception as e:
        print(f"[WARNING] Database initialization failed: {e}")
        print("[INFO] Application will start but database features may not work")
    
    try:
        init_models()
    except Exception as e:
        print(f"[WARNING] Model initialization failed: {e}")
        print("[INFO] Application will start but ML features may not work")

# Import routers - handle import errors gracefully
try:
    from api.routers import auth_router
    app.include_router(auth_router.router)
except Exception as e:
    print(f"Warning: Could not load auth_router: {e}")

try:
    from api.routers import shape_router
    app.include_router(shape_router.router)
except Exception as e:
    print(f"Warning: Could not load shape_router: {e}")

try:
    from api.routers import color_router
    app.include_router(color_router.router)
except Exception as e:
    print(f"Warning: Could not load color_router: {e}")

try:
    from api.routers import quiz_router
    app.include_router(quiz_router.router)
except Exception as e:
    print(f"Warning: Could not load quiz_router: {e}")

try:
    from api.routers import mission_router
    app.include_router(mission_router.router)
except Exception as e:
    print(f"Warning: Could not load mission_router: {e}")

try:
    from api.routers import pixy_learns_router
    app.include_router(pixy_learns_router.router)
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
