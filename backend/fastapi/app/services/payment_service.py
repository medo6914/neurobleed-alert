import logging
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class PaymentService:
    """Payment providers: Stripe, Paymob, PayPal. Each activates only when its key is set."""

    def __init__(self) -> None:
        self._client: httpx.AsyncClient | None = None

    @property
    def client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(timeout=httpx.Timeout(30.0))
        return self._client

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    def providers(self) -> dict[str, bool]:
        return {
            "stripe": bool(settings.STRIPE_SECRET_KEY),
            "paymob": bool(settings.PAYMOB_API_KEY),
            "paypal": bool(settings.PAYPAL_CLIENT_ID and settings.PAYPAL_CLIENT_SECRET),
        }

    # ---------------- Stripe ----------------

    async def stripe_create_payment_intent(
        self, amount_cents: int, currency: str = "usd"
    ) -> dict[str, Any] | None:
        if not settings.STRIPE_SECRET_KEY:
            return None
        try:
            resp = await self.client.post(
                "https://api.stripe.com/v1/payment_intents",
                auth=(settings.STRIPE_SECRET_KEY, ""),
                data={
                    "amount": amount_cents,
                    "currency": currency,
                    "automatic_payment_methods[enabled]": "true",
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return {"client_secret": data["client_secret"], "id": data["id"]}
        except Exception as e:
            logger.warning("Stripe payment intent failed: %s", e)
            return None

    # ---------------- Paymob ----------------

    async def paymob_create_payment(
        self, amount_cents: int, currency: str = "EGP", order_id: str | None = None
    ) -> dict[str, Any] | None:
        if not settings.PAYMOB_API_KEY:
            return None
        try:
            auth_resp = await self.client.post(
                "https://accept.paymob.com/api/auth/tokens",
                json={"api_key": settings.PAYMOB_API_KEY},
            )
            auth_resp.raise_for_status()
            token = auth_resp.json()["token"]

            order_resp = await self.client.post(
                "https://accept.paymob.com/api/ecommerce/orders",
                json={
                    "auth_token": token,
                    "delivery_needed": "false",
                    "amount_cents": str(amount_cents),
                    "currency": currency,
                    "items": [],
                },
            )
            order_resp.raise_for_status()
            order = order_resp.json()

            if settings.PAYMOB_INTEGRATION_ID:
                key_resp = await self.client.post(
                    "https://accept.paymob.com/api/acceptance/payment_keys",
                    json={
                        "auth_token": token,
                        "amount_cents": str(amount_cents),
                        "currency": currency,
                        "order_id": order["id"],
                        "integration_id": settings.PAYMOB_INTEGRATION_ID,
                    },
                )
                key_resp.raise_for_status()
                return {
                    "payment_key": key_resp.json()["token"],
                    "order_id": order["id"],
                }
            return {"order_id": order["id"]}
        except Exception as e:
            logger.warning("Paymob payment failed: %s", e)
            return None

    # ---------------- PayPal ----------------

    async def paypal_access_token(self) -> str | None:
        try:
            resp = await self.client.post(
                "https://api-m.sandbox.paypal.com/v1/oauth2/token",
                auth=(settings.PAYPAL_CLIENT_ID, settings.PAYPAL_CLIENT_SECRET),
                data={"grant_type": "client_credentials"},
            )
            resp.raise_for_status()
            return resp.json()["access_token"]
        except Exception as e:
            logger.warning("PayPal token failed: %s", e)
            return None

    async def paypal_create_order(self, amount_usd: float) -> dict[str, Any] | None:
        if not (settings.PAYPAL_CLIENT_ID and settings.PAYPAL_CLIENT_SECRET):
            return None
        token = await self.paypal_access_token()
        if not token:
            return None
        try:
            resp = await self.client.post(
                "https://api-m.sandbox.paypal.com/v2/checkout/orders",
                headers={"Authorization": f"Bearer {token}"},
                json={
                    "intent": "CAPTURE",
                    "purchase_units": [
                        {
                            "amount": {
                                "currency_code": "USD",
                                "value": f"{amount_usd:.2f}",
                            }
                        }
                    ],
                },
            )
            resp.raise_for_status()
            data = resp.json()
            approve_link = next(
                (l["href"] for l in data.get("links", []) if l.get("rel") == "approve"),
                None,
            )
            return {"order_id": data["id"], "approve_link": approve_link}
        except Exception as e:
            logger.warning("PayPal order failed: %s", e)
            return None


payment_service = PaymentService()
