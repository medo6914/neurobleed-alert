"""Seed demo users for the graduation presentation.

Creates (idempotently) the three demo accounts:

- admin@neurobleed.com  / Admin123!   (role: admin)
- doctor@neurobleed.com / Doctor123!  (role: doctor)
- patient@neurobleed.com / Patient123! (role: patient)

Usage:
    python -m app.seed_data
"""

import asyncio
import sys
from datetime import datetime, timezone

from sqlalchemy import select

from app.core.security import hash_password
from app.database import async_session
from app.models.enums import UserRole
from app.models.role import Role
from app.models.user import User

DEMO_USERS = [
    {
        "email": "admin@neurobleed.com",
        "password": "Admin123!",
        "full_name": "Demo Admin",
        "role": UserRole.ADMIN,
        "phone": "+201000000001",
    },
    {
        "email": "doctor@neurobleed.com",
        "password": "Doctor123!",
        "full_name": "Demo Doctor",
        "role": UserRole.DOCTOR,
        "phone": "+201000000002",
    },
    {
        "email": "patient@neurobleed.com",
        "password": "Patient123!",
        "full_name": "Demo Patient",
        "role": UserRole.PATIENT,
        "phone": "+201000000003",
    },
]


async def _assign_role(session, user: User, role_name: str) -> None:
    result = await session.execute(select(Role).where(Role.name == role_name))
    role = result.scalar_one_or_none()
    if role is None:
        return
    if role not in user.roles:
        user.roles.append(role)


async def seed() -> int:
    created = 0
    async with async_session() as session:
        for entry in DEMO_USERS:
            result = await session.execute(
                select(User).where(User.email == entry["email"])
            )
            existing = result.scalar_one_or_none()
            if existing is not None:
                await _assign_role(session, existing, entry["role"].value)
                print(f"[seed] exists: {entry['email']}")
                continue

            user = User(
                email=entry["email"],
                hashed_password=hash_password(entry["password"]),
                full_name=entry["full_name"],
                role=entry["role"],
                phone=entry["phone"],
                is_active=True,
                is_email_verified=True,
                is_phone_verified=True,
                last_password_change=datetime.now(timezone.utc),
            )
            session.add(user)
            await session.flush()
            await _assign_role(session, user, entry["role"].value)
            print(f"[seed] created: {entry['email']} (role={entry['role'].value})")
            created += 1

        await session.commit()
    return created


def main() -> None:
    try:
        created = asyncio.run(seed())
        print(f"[seed] done. created={created}")
    except Exception as exc:  # noqa: BLE001
        print(f"[seed] ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
