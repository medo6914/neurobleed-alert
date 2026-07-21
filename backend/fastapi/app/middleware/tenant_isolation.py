import logging
import uuid

from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from sqlalchemy import select

from app.database import get_db
from app.core.security import decode_access_token

logger = logging.getLogger(__name__)

TENANT_HEADER = "X-Tenant-ID"
TENANT_CLAIM = "tenant_id"
BYPASS_PATHS = {"/health", "/v1/auth/register", "/v1/auth/login", "/v1/auth/refresh", "/v1/auth/forgot-password", "/v1/auth/reset-password"}


class TenantIsolationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        path = request.url.path

        if path in BYPASS_PATHS or path.startswith(("/docs", "/openapi.json", "/redoc")):
            return await call_next(request)

        auth_header = request.headers.get("Authorization")
        tenant_id = None

        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header[7:]
            payload = decode_access_token(token)
            if payload:
                tenant_id = payload.get(TENANT_CLAIM)
                request.state.tenant_id = tenant_id
                request.state.user_id = payload.get("sub")
                request.state.user_role = payload.get("role")

        tenant_header = request.headers.get(TENANT_HEADER)
        if tenant_header and not tenant_id:
            try:
                tenant_id = uuid.UUID(tenant_header)
                request.state.tenant_id = str(tenant_id)
            except (ValueError, AttributeError):
                pass

        if not tenant_id:
            return await call_next(request)

        request.state.tenant_id = str(tenant_id) if isinstance(tenant_id, uuid.UUID) else tenant_id
        request.state.tenant_source = "header" if tenant_header else "token"

        response = await call_next(request)
        if request.state.tenant_id:
            response.headers["X-Tenant-ID"] = str(request.state.tenant_id)
        return response


def apply_tenant_isolation(app):
    app.add_middleware(TenantIsolationMiddleware)
