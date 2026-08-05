import functools
import logging
import re
import uuid
from typing import Any

from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import async_session
from app.models.audit_log import AuditLog

logger = logging.getLogger(__name__)

_PII_PATTERNS = [
    (re.compile(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"), "[EMAIL_REDACTED]"),
    (re.compile(r"\+\d{1,3}\d{6,14}"), "[PHONE_REDACTED]"),
    (re.compile(r"\b\d{3}[-.]?\d{2}[-.]?\d{4}\b"), "[SSN_REDACTED]"),
]


def _redact_pii(value: Any) -> Any:
    if isinstance(value, str):
        for pattern, replacement in _PII_PATTERNS:
            value = pattern.sub(replacement, value)
        return value
    if isinstance(value, dict):
        return {k: _redact_pii(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_redact_pii(v) for v in value]
    return value


def generate_correlation_id() -> str:
    return str(uuid.uuid4())


async def log_action(
    user_id: uuid.UUID | None,
    action: str,
    resource: str,
    resource_id: str | None = None,
    details: dict | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
    correlation_id: str | None = None,
) -> None:
    safe_details = _redact_pii(details) if details else None
    log = AuditLog(
        user_id=user_id,
        action=action,
        resource=resource,
        resource_id=resource_id,
        details=safe_details,
        ip_address=ip_address,
        user_agent=user_agent,
        correlation_id=correlation_id or generate_correlation_id(),
    )
    async with async_session() as session:
        session.add(log)
        await session.commit()
        logger.debug("Audit log: %s %s %s", action, resource, resource_id)


def audit_log(action: str, resource: str):
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            request: Request | None = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            if request is None:
                request = kwargs.get("request")

            response = await func(*args, **kwargs)

            if request:
                user_id = getattr(request.state, "user_id", None)
                res_id = request.path_params.get("id") or request.query_params.get("id")
                await log_action(
                    user_id=user_id,
                    action=action,
                    resource=resource,
                    resource_id=res_id,
                    ip_address=request.client.host if request.client else None,
                    user_agent=request.headers.get("user-agent"),
                    correlation_id=request.headers.get("X-Correlation-ID"),
                )
            return response

        return wrapper

    return decorator


async def audit_middleware(request: Request, call_next):
    correlation_id = (
        request.headers.get("X-Correlation-ID") or generate_correlation_id()
    )
    request.state.correlation_id = correlation_id

    response = await call_next(request)

    response.headers["X-Correlation-ID"] = correlation_id

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
            correlation_id=correlation_id,
        )
    return response
