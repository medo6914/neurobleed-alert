import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import settings
from app.database import init_db
from app.core.security import validate_production_config
from app.core.firebase import init_firebase
from app.core.rate_limiter import add_rate_limiting
from app.core.audit import log_action, generate_correlation_id
from app.core.redis import init_redis, close_redis
from app.services.monitoring_service import register_handlers
from app.middleware.security_headers import SecurityHeadersMiddleware
from app.middleware.tenant_isolation import apply_tenant_isolation
from app.api.v1 import router as v1_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    validate_production_config()
    await init_db()
    init_firebase()
    await init_redis()
    register_handlers()
    yield
    await close_redis()


class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response


class CorrelationIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        correlation_id = request.headers.get("X-Correlation-ID") or generate_correlation_id()
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
    allow_origins=["*"] if settings.ENVIRONMENT == "development" else ["https://neurobleed.com", "https://*.neurobleed.com", "https://app.neurobleed.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "0.1.0"}


@app.middleware("http")
async def audit_logging_middleware(request: Request, call_next):
    response = await call_next(request)
    if request.url.path.startswith("/api/v1/") and request.method not in ("GET", "HEAD", "OPTIONS"):
        await log_action(
            user_id=getattr(request.state, "user_id", None),
            action=request.method,
            resource=request.url.path,
            resource_id=request.path_params.get("id"),
            details={"query_params": dict(request.query_params)} if request.query_params else None,
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
            correlation_id=getattr(request.state, "correlation_id", None),
        )
    return response
