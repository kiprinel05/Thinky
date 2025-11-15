from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routers import shape_router, color_router, auth_router, quiz_router, mission_router
from api.utils import init_models
from database import init_db
# Import all models to ensure they are registered with SQLAlchemy Base before init_db()
from models.user_model import User
from models.mission_model import Mission, MissionProgress, QuizResult

app = FastAPI(title="Thinky Classification API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def startup_event():
    init_db()
    init_models()

app.include_router(auth_router.router)
app.include_router(shape_router.router)
app.include_router(color_router.router)
app.include_router(quiz_router.router)
app.include_router(mission_router.router)

@app.get("/")
def root():
    return {"message": "Thinky API is running with Shape + Color Models + Authentication + Quiz + Missions!"}
