import json
import logging
from datetime import datetime
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device import Device
from app.models.enums import DeviceStatus
from app.schemas.device import (
    DeviceCreate, DeviceUpdate, DeviceStatusUpdate, DeviceAssignRequest,
    DeviceHeartbeatRequest, BulkDeviceOperation,
)

logger = logging.getLogger(__name__)


class DeviceService:
    def __init__(self, db: AsyncSession, redis_client=None):
        self.db = db
        self.redis = redis_client

    async def register_device(self, data: DeviceCreate) -> Device:
        existing = await self.db.execute(
            select(Device).where(Device.serial_number == data.serial_number)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(400, "Serial number already registered")

        device = Device(**data.model_dump(exclude_none=True))
        self.db.add(device)
        await self.db.commit()
        await self.db.refresh(device)

        if self.redis:
            await self.redis.publish(
                "device:registered", json.dumps({"id": str(device.id)})
            )

        logger.info("Device registered", extra={"device_id": str(device.id), "serial": device.serial_number})
        return device

    async def get_device(self, device_id: UUID) -> Device:
        result = await self.db.execute(
            select(Device).where(Device.id == device_id, Device.is_active == True)
        )
        device = result.scalar_one_or_none()
        if not device:
            raise HTTPException(404, "Device not found")
        return device

    async def list_devices(
        self,
        page: int = 1,
        per_page: int = 50,
        sort_by: str | None = None,
        sort_order: str = "desc",
        status: DeviceStatus | None = None,
        device_type=None,
        hospital_id: UUID | None = None,
        patient_id: UUID | None = None,
        search: str | None = None,
    ) -> tuple[list[Device], int]:
        query = select(Device).where(Device.is_active == True)

        if status:
            query = query.where(Device.status == status)
        if device_type:
            query = query.where(Device.device_type == device_type)
        if hospital_id:
            query = query.where(Device.hospital_id == hospital_id)
        if patient_id:
            query = query.where(Device.patient_id == patient_id)
        if search:
            query = query.where(
                Device.serial_number.ilike(f"%{search}%")
                | Device.device_name.ilike(f"%{search}%")
            )

        count_query = select(func.count()).select_from(query.subquery())
        total_result = await self.db.execute(count_query)
        total = total_result.scalar() or 0

        sort_column = getattr(Device, sort_by, Device.created_at) if sort_by else Device.created_at
        if sort_order == "asc":
            query = query.order_by(sort_column.asc())
        else:
            query = query.order_by(sort_column.desc())

        offset = (page - 1) * per_page
        query = query.offset(offset).limit(per_page)

        result = await self.db.execute(query)
        devices = result.scalars().all()

        return list(devices), total

    async def update_device(self, device_id: UUID, data: DeviceUpdate) -> Device:
        device = await self.get_device(device_id)
        for field, value in data.model_dump(exclude_none=True).items():
            setattr(device, field, value)
        await self.db.commit()
        await self.db.refresh(device)

        if self.redis:
            await self.redis.publish(
                "device:updated", json.dumps({"id": str(device.id)})
            )

        logger.info("Device updated", extra={"device_id": str(device.id)})
        return device

    async def delete_device(self, device_id: UUID) -> None:
        device = await self.get_device(device_id)
        device.is_active = False
        await self.db.commit()
        logger.info("Device deactivated", extra={"device_id": str(device.id)})

    async def update_status(self, device_id: UUID, data: DeviceStatusUpdate) -> Device:
        device = await self.get_device(device_id)
        for field, value in data.model_dump(exclude_none=True).items():
            setattr(device, field, value)
        device.last_seen = datetime.utcnow()
        await self.db.commit()
        await self.db.refresh(device)

        if self.redis:
            await self.redis.publish(
                "device:status",
                json.dumps({
                    "id": str(device.id),
                    "status": device.status.value,
                    "battery": device.battery_level,
                    "signal": device.signal_strength,
                }),
            )

        return device

    async def assign_device(self, device_id: UUID, data: DeviceAssignRequest) -> Device:
        device = await self.get_device(device_id)
        if data.patient_id is not None:
            existing = await self.db.execute(
                select(Device).where(
                    Device.patient_id == data.patient_id,
                    Device.is_active == True,
                    Device.id != device_id,
                )
            )
            if existing.scalar_one_or_none():
                raise HTTPException(400, "Patient already has an assigned device")
        device.patient_id = data.patient_id
        device.hospital_id = data.hospital_id
        device.department = data.department
        await self.db.commit()
        await self.db.refresh(device)
        logger.info("Device assigned", extra={
            "device_id": str(device.id),
            "patient_id": str(data.patient_id) if data.patient_id else None,
        })
        return device

    async def heartbeat(self, device_id: UUID, data: DeviceHeartbeatRequest) -> Device:
        device = await self.get_device(device_id)
        device.last_heartbeat = datetime.utcnow()
        device.last_seen = datetime.utcnow()
        if data.battery_level is not None:
            device.battery_level = data.battery_level
        if data.signal_strength is not None:
            device.signal_strength = data.signal_strength
        if data.temperature is not None:
            device.temperature = data.temperature
        if data.charging_status is not None:
            device.charging_status = data.charging_status
        if data.lte_signal is not None:
            device.lte_signal = data.lte_signal
        if data.sim_status is not None:
            device.sim_status = data.sim_status
        if data.ble_status is not None:
            device.ble_status = data.ble_status
        device.status = DeviceStatus.ONLINE
        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def bulk_operation(self, data: BulkDeviceOperation):
        results = []
        for device_id in data.device_ids:
            try:
                device = await self.get_device(device_id)
                if data.operation == "activate":
                    device.is_active = True
                elif data.operation == "deactivate":
                    device.is_active = False
                elif data.operation == "maintenance":
                    device.status = DeviceStatus.MAINTENANCE
                elif data.operation == "update_firmware" and data.firmware_version:
                    device.firmware_version = data.firmware_version
                    device.status = DeviceStatus.UPDATING
                results.append({"id": str(device_id), "success": True})
            except HTTPException:
                results.append({"id": str(device_id), "success": False})
        await self.db.commit()
        return results

    async def get_diagnostics(self, device_id: UUID) -> dict:
        device = await self.get_device(device_id)
        uptime = None
        if device.last_heartbeat:
            uptime = int((datetime.utcnow() - device.last_heartbeat).total_seconds())
        return {
            "device_id": device.id,
            "status": device.status,
            "battery_level": device.battery_level,
            "signal_strength": device.signal_strength,
            "firmware_version": device.firmware_version,
            "hardware_version": device.hardware_version,
            "temperature": device.temperature,
            "charging_status": device.charging_status,
            "lte_signal": device.lte_signal,
            "sim_status": device.sim_status,
            "ble_status": device.ble_status,
            "last_seen": device.last_seen,
            "uptime": uptime,
            "memory_usage": None,
            "storage_usage": None,
        }
