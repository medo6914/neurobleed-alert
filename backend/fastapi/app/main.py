import logging
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import settings
from app.database import init_db, check_database
from app.core.security import validate_production_config
from app.core.firebase import init_firebase
from app.core.rate_limiter import add_rate_limiting
from app.core.audit import log_action, generate_correlation_id
from app.core.redis import init_redis, close_redis
from app.core.migrations import run_migrations
from app.services.monitoring_service import register_handlers
from app.services.maps_service import maps_service
from app.services.weather_service import weather_service
from app.services.medical_service import medical_service
from app.services.payment_service import payment_service
from app.services.file_service import file_service
from app.services.notification_service import notification_dispatcher
from app.ai.service import ai_service
from app.ai.llm_gateway import llm_gateway
from app.middleware.security_headers import SecurityHeadersMiddleware
from app.middleware.tenant_isolation import apply_tenant_isolation
from app.api.v1 import router as v1_router
from app.seed_data import seed as seed_demo_data

logger = logging.getLogger(__name__)


def init_sentry():
    if not settings.SENTRY_DSN:
        return False
    try:
        import sentry_sdk

        sentry_sdk.init(
            dsn=settings.SENTRY_DSN,
            environment=settings.ENVIRONMENT,
            traces_sample_rate=0.1,
        )
        logger.info("Sentry initialized")
        return True
    except Exception as e:
        logger.warning("Sentry init failed: %s", e)
        return False


@asynccontextmanager
async def lifespan(app: FastAPI):
    validate_production_config()
    init_sentry()
    run_migrations()
    await init_db()
    await seed_demo_data()
    init_firebase()
    await init_redis()
    register_handlers()
    await ai_service.initialize()
    yield
    await close_redis()
    await maps_service.aclose()
    await weather_service.aclose()
    await medical_service.aclose()
    await payment_service.aclose()
    await notification_dispatcher.aclose()
    await llm_gateway.aclose()


class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


class CorrelationIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        correlation_id = (
            request.headers.get("X-Correlation-ID") or generate_correlation_id()
        )
        request.state.correlation_id = correlation_id
        response = await call_next(request)
        response.headers["X-Correlation-ID"] = correlation_id
        return response


app = FastAPI(
    title="NeuroBleed Alert API",
    description="Risk Assessment & Decision Support System for Intracranial Hemorrhage",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(RequestIDMiddleware)
app.add_middleware(CorrelationIDMiddleware)
app.add_middleware(SecurityHeadersMiddleware)

add_rate_limiting(app)
apply_tenant_isolation(app)
app.include_router(v1_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"]
    if settings.ENVIRONMENT == "development"
    else [
        "https://neurobleed.com",
        "https://*.neurobleed.com",
        "https://app.neurobleed.com",
        "https://medo6914.github.io",
        "https://*.github.io",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    db_ok = await check_database()
    body = {
        "status": "ok" if db_ok else "degraded",
        "version": "0.1.0",
        "database": "ok" if db_ok else "error",
        "database_backend": "postgresql"
        if settings.DATABASE_URL.startswith("postgresql")
        else "sqlite",
        "maps": "nominatim/osrm/overpass",
        "llm_providers": llm_gateway.providers_available(),
        "firebase": bool(settings.FIREBASE_CREDENTIALS_PATH),
        "sentry": bool(settings.SENTRY_DSN),
        "weather": weather_service.configured(),
        "payments": payment_service.providers(),
        "files": file_service.cloudinary_configured(),
    }
    if not db_ok:
        from starlette.responses import JSONResponse

        return JSONResponse(status_code=503, content=body)
    return body


@app.middleware("http")
async def audit_logging_middleware(request: Request, call_next):
    response = await call_next(request)
    if request.url.path.startswith("/api/v1/") and request.method not in (
        "GET",
        "HEAD",
        "OPTIONS",
    ):
        await log_action(
            user_id=getattr(request.state, "user_id", None),
            action=request.method,
            resource=request.url.path,
            resource_id=request.path_params.get("id"),
            details={"query_params": dict(request.query_params)}
            if request.query_params
            else None,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
            correlation_id=getattr(request.state, "correlation_id", None),
        )
    return response
