from fastapi import APIRouter

from app.api.v1.biometrics import router as biometrics_router
from app.api.v1.calendar import router as calendar_router
from app.api.v1.dashboard import router as dashboard_router
from app.api.v1.health import router as health_router
from app.api.v1.training_plans import router as training_plans_router
from app.api.v1.auth import router as auth_router

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router)
api_router.include_router(health_router)
api_router.include_router(training_plans_router)
api_router.include_router(calendar_router)
api_router.include_router(biometrics_router)
api_router.include_router(dashboard_router)
