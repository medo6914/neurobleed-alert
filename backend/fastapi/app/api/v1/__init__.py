from fastapi import APIRouter

from app.api.v1 import auth, patients, devices, readings, alerts, device_ws, device_history
from app.ai import ai_router

router = APIRouter(prefix="/v1")
router.include_router(auth.router)
router.include_router(patients.router)
router.include_router(devices.router)
router.include_router(readings.router)
router.include_router(alerts.router)
router.include_router(device_ws.router)
router.include_router(device_history.router)
router.include_router(ai_router)
