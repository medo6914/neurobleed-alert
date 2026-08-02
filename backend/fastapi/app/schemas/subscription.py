from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class SubscriptionCreate(BaseModel):
    hospital_id: UUID
    tier: str = "free"
    max_patients: int | None = None
    max_devices: int | None = None
    max_users: int | None = None
    price_monthly: float | None = None
    trial_end: datetime | None = None
    features: dict | None = None


class SubscriptionUpdate(BaseModel):
    tier: str | None = None
    status: str | None = None
    max_patients: int | None = None
    max_devices: int | None = None
    max_users: int | None = None
    price_monthly: float | None = None
    features: dict | None = None


class SubscriptionResponse(BaseModel):
    id: UUID
    hospital_id: UUID
    tier: str
    status: str
    stripe_subscription_id: str | None
    stripe_customer_id: str | None
    current_period_start: datetime | None
    current_period_end: datetime | None
    canceled_at: datetime | None
    trial_end: datetime | None
    max_patients: int | None
    max_devices: int | None
    max_users: int | None
    features: dict | None
    price_monthly: float | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class InvoiceResponse(BaseModel):
    id: UUID
    hospital_id: UUID
    subscription_id: UUID
    amount: float
    currency: str
    status: str
    paid_at: datetime | None
    due_date: datetime | None
    period_start: datetime | None
    period_end: datetime | None
    pdf_url: str | None
    created_at: datetime

    class Config:
        from_attributes = True
