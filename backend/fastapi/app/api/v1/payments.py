import logging
from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.payment_service import payment_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/payments", tags=["payments"])


class PaymentIntentRequest(BaseModel):
    amount_cents: int = Field(..., gt=0)
    currency: str = "usd"


@router.get("/providers")
async def providers(
    current_user: User = Depends(get_current_user),
):
    return {
        "providers": payment_service.providers(),
        "note": "Add STRIPE_SECRET_KEY, PAYMOB_API_KEY or PAYPAL_CLIENT_ID/SECRET to .env to activate",
    }


@router.post("/stripe/payment-intent")
async def stripe_payment_intent(
    data: PaymentIntentRequest,
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    result = await payment_service.stripe_create_payment_intent(
        data.amount_cents, data.currency
    )
    if result is None:
        return {"status": "unconfigured", "message": "STRIPE_SECRET_KEY not set"}
    return {"status": "ok", **result}


@router.post("/paymob/payment")
async def paymob_payment(
    data: PaymentIntentRequest,
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    result = await payment_service.paymob_create_payment(
        data.amount_cents, data.currency
    )
    if result is None:
        return {"status": "unconfigured", "message": "PAYMOB_API_KEY not set"}
    return {"status": "ok", **result}


@router.post("/paypal/order")
async def paypal_order(
    data: PaymentIntentRequest,
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    result = await payment_service.paypal_create_order(data.amount_cents / 100.0)
    if result is None:
        return {"status": "unconfigured", "message": "PAYPAL_CLIENT_ID/SECRET not set"}
    return {"status": "ok", **result}
