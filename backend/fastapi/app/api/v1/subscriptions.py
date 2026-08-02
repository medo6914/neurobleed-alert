import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.subscription import Subscription, Invoice
from app.models.hospital import Hospital
from app.models.user import User
from app.models.enums import SubscriptionTier, SubscriptionStatus
from app.schemas.subscription import (
    SubscriptionCreate, SubscriptionUpdate, SubscriptionResponse,
    InvoiceResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/billing", tags=["billing"])


@router.post("/subscribe", response_model=SubscriptionResponse, status_code=status.HTTP_201_CREATED)
async def create_subscription(
    data: SubscriptionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    hospital_result = await db.execute(select(Hospital).where(Hospital.id == data.hospital_id))
    hospital = hospital_result.scalar_one_or_none()
    if not hospital:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hospital not found")

    existing = await db.execute(
        select(Subscription).where(Subscription.hospital_id == data.hospital_id, Subscription.is_deleted == False)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Hospital already has a subscription")

    subscription = Subscription(
        hospital_id=data.hospital_id,
        tier=SubscriptionTier(data.tier) if data.tier else SubscriptionTier.FREE,
        status=SubscriptionStatus.ACTIVE,
        max_patients=data.max_patients,
        max_devices=data.max_devices,
        max_users=data.max_users,
        price_monthly=data.price_monthly,
        trial_end=data.trial_end,
        features=data.features,
    )
    db.add(subscription)
    await db.commit()
    await db.refresh(subscription)
    logger.info("Subscription created", extra={"hospital_id": str(data.hospital_id), "tier": data.tier})
    return subscription


@router.get("/subscriptions", response_model=list[SubscriptionResponse])
async def list_subscriptions(
    hospital_id: str | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    query = select(Subscription).where(Subscription.is_deleted == False)
    if hospital_id:
        query = query.where(Subscription.hospital_id == hospital_id)
    query = query.order_by(desc(Subscription.created_at))
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/subscriptions/{subscription_id}", response_model=SubscriptionResponse)
async def get_subscription(
    subscription_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    result = await db.execute(
        select(Subscription).where(Subscription.id == subscription_id, Subscription.is_deleted == False)
    )
    subscription = result.scalar_one_or_none()
    if not subscription:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")
    return subscription


@router.put("/subscriptions/{subscription_id}", response_model=SubscriptionResponse)
async def update_subscription(
    subscription_id: uuid.UUID,
    data: SubscriptionUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    result = await db.execute(
        select(Subscription).where(Subscription.id == subscription_id, Subscription.is_deleted == False)
    )
    subscription = result.scalar_one_or_none()
    if not subscription:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

    update_data = data.model_dump(exclude_unset=True)
    if "tier" in update_data and update_data["tier"]:
        update_data["tier"] = SubscriptionTier(update_data["tier"])
    if "status" in update_data and update_data["status"]:
        update_data["status"] = SubscriptionStatus(update_data["status"])

    for key, value in update_data.items():
        setattr(subscription, key, value)

    await db.commit()
    await db.refresh(subscription)
    return subscription


@router.post("/subscriptions/{subscription_id}/cancel", response_model=SubscriptionResponse)
async def cancel_subscription(
    subscription_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    result = await db.execute(
        select(Subscription).where(Subscription.id == subscription_id, Subscription.is_deleted == False)
    )
    subscription = result.scalar_one_or_none()
    if not subscription:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found")

    subscription.status = SubscriptionStatus.CANCELED
    subscription.canceled_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(subscription)
    logger.info("Subscription canceled", extra={"subscription_id": str(subscription_id)})
    return subscription


@router.get("/invoices", response_model=list[InvoiceResponse])
async def list_invoices(
    hospital_id: str | None = Query(None),
    subscription_id: str | None = Query(None),
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    query = select(Invoice).where(Invoice.is_deleted == False)
    if hospital_id:
        query = query.where(Invoice.hospital_id == hospital_id)
    if subscription_id:
        query = query.where(Invoice.subscription_id == subscription_id)
    query = query.order_by(desc(Invoice.created_at)).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/invoices/{invoice_id}", response_model=InvoiceResponse)
async def get_invoice(
    invoice_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    result = await db.execute(select(Invoice).where(Invoice.id == invoice_id, Invoice.is_deleted == False))
    invoice = result.scalar_one_or_none()
    if not invoice:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invoice not found")
    return invoice
