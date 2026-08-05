import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.user import User
from app.models.enums import ProvisioningKeyStatus, DeviceType
from app.schemas.provisioning import (
    ProvisioningKeyCreate,
    ProvisioningKeyResponse,
    ProvisioningKeyListResponse,
    ProvisioningClaimRequest,
    ProvisioningClaimResponse,
)
from app.services.provisioning_service import ProvisioningService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/devices", tags=["devices"])


async def get_provisioning_service(
    db: AsyncSession = Depends(get_db),
) -> ProvisioningService:
    return ProvisioningService(db)


@router.post(
    "/provisioning/keys",
    response_model=ProvisioningKeyResponse,
    status_code=status.HTTP_201_CREATED,
)
async def generate_provisioning_key(
    data: ProvisioningKeyCreate,
    service: ProvisioningService = Depends(get_provisioning_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_CREATE)),
):
    return await service.generate_key(data, created_by_id=current_user.id)


@router.get("/provisioning/keys", response_model=ProvisioningKeyListResponse)
async def list_provisioning_keys(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    status: ProvisioningKeyStatus | None = None,
    device_type: DeviceType | None = None,
    service: ProvisioningService = Depends(get_provisioning_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_LIST)),
):
    keys, total = await service.list_keys(
        page=page,
        per_page=per_page,
        status=status,
        device_type=device_type,
    )
    total_pages = max(1, (total + per_page - 1) // per_page)
    return ProvisioningKeyListResponse(
        items=[ProvisioningKeyResponse.model_validate(k) for k in keys],
        total=total,
        page=page,
        per_page=per_page,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1,
    )


@router.get("/provisioning/keys/{key_id}", response_model=ProvisioningKeyResponse)
async def get_provisioning_key(
    key_id: UUID,
    service: ProvisioningService = Depends(get_provisioning_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_VIEW)),
):
    return await service.get_key(key_id)


@router.post(
    "/provisioning/keys/{key_id}/revoke", response_model=ProvisioningKeyResponse
)
async def revoke_provisioning_key(
    key_id: UUID,
    service: ProvisioningService = Depends(get_provisioning_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_UPDATE)),
):
    return await service.revoke_key(key_id)


@router.post("/provisioning/claim", response_model=ProvisioningClaimResponse)
async def claim_device(
    data: ProvisioningClaimRequest,
    service: ProvisioningService = Depends(get_provisioning_service),
):
    try:
        result = await service.claim_device(data)
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Device claim failed", exc_info=e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Claim processing failed",
        )
