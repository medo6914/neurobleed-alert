from fastapi import APIRouter

from app.api.v1 import auth, patients, devices, readings, alerts, device_ws, device_history
from app.api.v1 import clinical_reports, emergency, fhir, hl7, subscriptions, provisioning, analytics
from app.api.v1 import maps, notifications, medical, weather, payments, files
from app.ai import ai_router

router = APIRouter(prefix="/v1")
router.include_router(auth.router)
router.include_router(patients.router)
router.include_router(devices.router)
router.include_router(readings.router)
router.include_router(alerts.router)
router.include_router(device_ws.router)
router.include_router(device_history.router)
router.include_router(clinical_reports.router)
router.include_router(emergency.router)
router.include_router(fhir.router)
router.include_router(hl7.router)
router.include_router(subscriptions.router)
router.include_router(provisioning.router)
router.include_router(analytics.router)
router.include_router(maps.router)
router.include_router(notifications.router)
router.include_router(medical.router)
router.include_router(weather.router)
router.include_router(payments.router)
router.include_router(files.router)
router.include_router(ai_router)
