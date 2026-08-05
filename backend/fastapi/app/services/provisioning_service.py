import logging
import secrets
from datetime import datetime, timezone
from uuid import UUID

from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device import Device
from app.models.device_provisioning import DeviceProvisioningKey
from app.models.enums import ProvisioningKeyStatus, DeviceStatus, DeviceEventType
from app.models.device_event_log import DeviceEventLog
from app.schemas.provisioning import ProvisioningKeyCreate, ProvisioningClaimRequest

logger = logging.getLogger(__name__)


class ProvisioningService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def generate_key(
        self, data: ProvisioningKeyCreate, created_by_id: UUID | None = None
    ) -> DeviceProvisioningKey:
        key = secrets.token_hex(16)

        provisioning_key = DeviceProvisioningKey(
            key=key,
            device_type=data.device_type,
            label=data.label,
            hospital_id=data.hospital_id,
            status=ProvisioningKeyStatus.ACTIVE,
            expires_at=data.expires_at,
            max_uses=data.max_uses,
            created_by_id=created_by_id,
            provisioning_metadata=data.metadata,
        )
        self.db.add(provisioning_key)
        await self.db.commit()
        await self.db.refresh(provisioning_key)

        logger.info(
            "Provisioning key generated",
            extra={
                "key_id": str(provisioning_key.id),
                "device_type": data.device_type.value,
            },
        )
        return provisioning_key

    async def get_key(self, key_id: UUID) -> DeviceProvisioningKey:
        result = await self.db.execute(
            select(DeviceProvisioningKey).where(
                DeviceProvisioningKey.id == key_id,
                DeviceProvisioningKey.is_deleted == False,
            )
        )
        key_obj = result.scalar_one_or_none()
        if not key_obj:
            raise HTTPException(404, "Provisioning key not found")
        return key_obj

    async def list_keys(
        self,
        page: int = 1,
        per_page: int = 50,
        status: ProvisioningKeyStatus | None = None,
        device_type=None,
    ) -> tuple[list[DeviceProvisioningKey], int]:
        query = select(DeviceProvisioningKey).where(
            DeviceProvisioningKey.is_deleted == False
        )

        if status:
            query = query.where(DeviceProvisioningKey.status == status)
        if device_type:
            query = query.where(DeviceProvisioningKey.device_type == device_type)

        count_query = select(func.count()).select_from(query.subquery())
        total_result = await self.db.execute(count_query)
        total = total_result.scalar() or 0

        query = query.order_by(DeviceProvisioningKey.created_at.desc())
        query = query.offset((page - 1) * per_page).limit(per_page)

        result = await self.db.execute(query)
        keys = result.scalars().all()

        return list(keys), total

    async def revoke_key(self, key_id: UUID) -> DeviceProvisioningKey:
        key_obj = await self.get_key(key_id)
        key_obj.status = ProvisioningKeyStatus.REVOKED
        await self.db.commit()
        await self.db.refresh(key_obj)
        logger.info("Provisioning key revoked", extra={"key_id": str(key_id)})
        return key_obj

    async def claim_device(self, data: ProvisioningClaimRequest) -> dict:
        result = await self.db.execute(
            select(DeviceProvisioningKey).where(
                DeviceProvisioningKey.key == data.provisioning_key,
                DeviceProvisioningKey.is_deleted == False,
            )
        )
        key_obj = result.scalar_one_or_none()

        if not key_obj:
            raise HTTPException(400, "Invalid provisioning key")

        if key_obj.status != ProvisioningKeyStatus.ACTIVE:
            raise HTTPException(400, f"Provisioning key is {key_obj.status.value}")

        if key_obj.expires_at and key_obj.expires_at < datetime.now(timezone.utc):
            key_obj.status = ProvisioningKeyStatus.EXPIRED
            await self.db.commit()
            raise HTTPException(400, "Provisioning key has expired")

        if key_obj.max_uses and key_obj.use_count >= key_obj.max_uses:
            raise HTTPException(400, "Provisioning key has reached maximum uses")

        existing = await self.db.execute(
            select(Device).where(Device.serial_number == data.serial_number)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(400, "Serial number already registered")

        device = Device(
            serial_number=data.serial_number,
            device_name=data.device_name,
            device_type=data.device_type or key_obj.device_type,
            mac_address=data.mac_address,
            firmware_version=data.firmware_version,
            hardware_version=data.hardware_version,
            hospital_id=key_obj.hospital_id,
            status=DeviceStatus.ONLINE,
        )
        self.db.add(device)
        await self.db.flush()

        key_obj.use_count += 1
        key_obj.used_at = datetime.now(timezone.utc)
        key_obj.used_by_device_id = device.id
        if key_obj.max_uses and key_obj.use_count >= key_obj.max_uses:
            key_obj.status = ProvisioningKeyStatus.USED

        event_log = DeviceEventLog(
            device_id=device.id,
            event_type=DeviceEventType.PROVISIONED,
            description=f"Device provisioned via key {data.provisioning_key[:8]}...",
            new_value=device.serial_number,
            event_metadata={"provisioning_key_id": str(key_obj.id)},
        )
        self.db.add(event_log)

        await self.db.commit()
        await self.db.refresh(device)

        logger.info(
            "Device claimed via provisioning",
            extra={"device_id": str(device.id), "serial": data.serial_number},
        )

        return {
            "success": True,
            "device_id": device.id,
            "serial_number": device.serial_number,
            "message": "Device claimed and registered successfully",
            "device": {
                "id": str(device.id),
                "serial_number": device.serial_number,
                "device_name": device.device_name,
                "device_type": device.device_type.value,
                "status": device.status.value,
            },
        }
