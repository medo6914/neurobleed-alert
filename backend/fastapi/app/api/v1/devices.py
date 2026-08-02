import logging

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Literal
from uuid import UUID

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.device import Device
from app.models.device_event_log import DeviceEventLog
from app.models.device_diagnostic_log import DeviceDiagnosticLog
from app.models.user import User
from app.models.enums import DeviceType, DeviceStatus, DeviceEventType
from app.schemas.device import (
    DeviceCreate, DeviceUpdate, DeviceResponse, DeviceListResponse,
    DeviceStatusUpdate, DeviceAssignRequest, DeviceDiagnosticResponse,
    DeviceHeartbeatRequest, DeviceCertRequest, BulkDeviceOperation,
)
from app.schemas.diagnostic_log import (
    DiagnosticLogCreate, DiagnosticLogResponse, DiagnosticLogListResponse,
)
from app.services.device_service import DeviceService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/devices", tags=["devices"])


async def get_device_service(db: AsyncSession = Depends(get_db)) -> DeviceService:
    return DeviceService(db)


# ===== CRUD =====


@router.post("/", response_model=DeviceResponse, status_code=status.HTTP_201_CREATED)
async def register_device(
    data: DeviceCreate,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_CREATE)),
):
    return await service.register_device(data)


@router.get("/", response_model=DeviceListResponse)
async def list_devices(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=1000),
    sort_by: str | None = Query(None),
    sort_order: Literal["asc", "desc"] = Query("desc"),
    status: DeviceStatus | None = None,
    device_type: DeviceType | None = None,
    hospital_id: UUID | None = None,
    patient_id: UUID | None = None,
    search: str | None = Query(None, min_length=2),
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_LIST)),
):
    devices, total = await service.list_devices(
        page=page, per_page=per_page, sort_by=sort_by, sort_order=sort_order,
        status=status, device_type=device_type,
        hospital_id=hospital_id, patient_id=patient_id, search=search,
    )
    total_pages = max(1, (total + per_page - 1) // per_page)
    return DeviceListResponse(
        items=[DeviceResponse.model_validate(d) for d in devices],
        total=total, page=page, per_page=per_page,
        total_pages=total_pages,
        has_next=page < total_pages, has_prev=page > 1,
    )


@router.get("/{device_id}", response_model=DeviceResponse)
async def get_device(
    device_id: UUID,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_VIEW)),
):
    return await service.get_device(device_id)


@router.patch("/{device_id}", response_model=DeviceResponse)
async def update_device(
    device_id: UUID,
    data: DeviceUpdate,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_UPDATE)),
):
    return await service.update_device(device_id, data)


@router.delete("/{device_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_device(
    device_id: UUID,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_DELETE)),
):
    await service.delete_device(device_id)


# ===== Status & Telemetry =====


@router.patch("/{device_id}/status", response_model=DeviceResponse)
async def update_device_status(
    device_id: UUID,
    data: DeviceStatusUpdate,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_UPDATE)),
):
    return await service.update_status(device_id, data)


@router.post("/{device_id}/heartbeat", response_model=DeviceResponse)
async def device_heartbeat(
    device_id: UUID,
    data: DeviceHeartbeatRequest,
    service: DeviceService = Depends(get_device_service),
):
    return await service.heartbeat(device_id, data)


# ===== Assignment =====


@router.post("/{device_id}/assign", response_model=DeviceResponse)
async def assign_device(
    device_id: UUID,
    data: DeviceAssignRequest,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_UPDATE)),
):
    return await service.assign_device(device_id, data)


@router.post("/{device_id}/unassign", response_model=DeviceResponse)
async def unassign_device(
    device_id: UUID,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_UPDATE)),
):
    return await service.assign_device(
        device_id, DeviceAssignRequest(patient_id=None, hospital_id=None, department=None)
    )


# ===== Diagnostics =====


@router.get("/{device_id}/diagnostics", response_model=DeviceDiagnosticResponse)
async def device_diagnostics(
    device_id: UUID,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_VIEW)),
):
    return await service.get_diagnostics(device_id)


@router.post("/{device_id}/diagnostics/log", response_model=DiagnosticLogResponse, status_code=status.HTTP_201_CREATED)
async def log_device_diagnostics(
    device_id: UUID,
    data: DiagnosticLogCreate,
    service: DeviceService = Depends(get_device_service),
):
    from datetime import datetime, timezone
    log_entry = DeviceDiagnosticLog(
        device_id=device_id,
        status=data.status,
        battery_level=data.battery_level,
        signal_strength=data.signal_strength,
        temperature=data.temperature,
        charging_status=data.charging_status,
        lte_signal=data.lte_signal,
        sim_status=data.sim_status,
        ble_status=data.ble_status,
        wifi_status=data.wifi_status,
        memory_usage=data.memory_usage,
        storage_usage=data.storage_usage,
        firmware_version=data.firmware_version,
        uptime_seconds=data.uptime_seconds,
        error_code=data.error_code,
        error_message=data.error_message,
        raw_data=data.raw_data,
        recorded_at=data.recorded_at or datetime.now(timezone.utc),
    )
    service.db.add(log_entry)
    await service.db.commit()
    await service.db.refresh(log_entry)
    return log_entry


@router.get("/{device_id}/diagnostics/logs", response_model=DiagnosticLogListResponse)
async def list_device_diagnostics_log(
    device_id: UUID,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_VIEW)),
):
    query = select(DeviceDiagnosticLog).where(
        DeviceDiagnosticLog.device_id == device_id,
    ).order_by(DeviceDiagnosticLog.recorded_at.desc())

    count_query = select(func.count()).select_from(query.subquery())
    total_result = await service.db.execute(count_query)
    total = total_result.scalar() or 0

    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await service.db.execute(query)
    logs = result.scalars().all()

    total_pages = max(1, (total + per_page - 1) // per_page)
    return DiagnosticLogListResponse(
        items=[DiagnosticLogResponse.model_validate(l) for l in logs],
        total=total, page=page, per_page=per_page,
        total_pages=total_pages,
        has_next=page < total_pages, has_prev=page > 1,
    )


# ===== Event Log =====


@router.get("/{device_id}/events", response_model=list[dict])
async def list_device_events(
    device_id: UUID,
    event_type: DeviceEventType | None = None,
    limit: int = Query(50, le=200),
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_VIEW)),
):
    query = select(DeviceEventLog).where(
        DeviceEventLog.device_id == device_id,
    )
    if event_type:
        query = query.where(DeviceEventLog.event_type == event_type)
    query = query.order_by(DeviceEventLog.event_time.desc()).limit(limit)
    result = await service.db.execute(query)
    events = result.scalars().all()
    return [
        {
            "id": str(e.id),
            "event_type": e.event_type.value,
            "description": e.description,
            "event_time": e.event_time.isoformat() if e.event_time else None,
            "metadata": e.event_metadata,
        }
        for e in events
    ]


# ===== Bulk Operations =====


@router.post("/bulk")
async def bulk_device_operation(
    data: BulkDeviceOperation,
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_UPDATE)),
):
    return await service.bulk_operation(data)


# ===== Certificate =====


@router.post("/{device_id}/certificate")
async def register_device_certificate(
    device_id: UUID,
    data: DeviceCertRequest,
    service: DeviceService = Depends(get_device_service),
):
    device = await service.get_device(device_id)
    device.certificate_thumbprint = data.certificate
    device.public_key = data.public_key
    await service.db.commit()
    logger.info("Device certificate registered", extra={"device_id": str(device_id)})
    return {"status": "ok"}


# ===== Firmware =====


@router.post("/{device_id}/ota")
async def trigger_ota_update(
    device_id: UUID,
    firmware_version: str = Query(...),
    service: DeviceService = Depends(get_device_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_UPDATE)),
):
    device = await service.get_device(device_id)
    old_version = device.firmware_version
    device.firmware_version = firmware_version
    device.status = DeviceStatus.UPDATING
    await service.db.commit()
    await service.db.refresh(device)
    logger.info(
        "OTA update initiated",
        extra={
            "device_id": str(device.id),
            "old_firmware": old_version,
            "new_firmware": firmware_version,
        },
    )
    return {
        "device_id": str(device.id),
        "old_firmware": old_version,
        "new_firmware": firmware_version,
        "status": "ota_initiated",
    }
