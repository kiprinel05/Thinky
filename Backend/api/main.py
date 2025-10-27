from fastapi import FastAPI
from api.routers import shape_router, color_router
from api.utils import init_models

app = FastAPI(title="Thinky Classification API")

@app.on_event("startup")
def startup_event():
    init_models()

app.include_router(shape_router.router)
app.include_router(color_router.router)

@app.get("/")
def root():
    return {"message": "Thinky API is running with Shape + Color Models!"}
