"""Seed system data only (roles + hospitals).

No user accounts are created here. The app is official: accounts are
created only through registration. A user who registers with an email
listed in settings.SUPER_ADMIN_EMAILS is automatically promoted to
super_admin by the auth service (never via UI role selection).

All legacy demo accounts are removed on every boot.
"""

import asyncio
import sys
from datetime import datetime, timezone

from sqlalchemy import delete, select

from app.config import settings
from app.database import async_session, init_db
from app.models.enums import UserRole, HospitalType
from app.models.hospital import Hospital
from app.models.role import Role
from app.models.user import User
from app.models.user_role import user_role

LEGACY_DEMO_EMAILS = [
    "admin@neurobleed.com",
    "doctor@neurobleed.com",
    "patient@neurobleed.com",
    "medomaree11@gmail.com",
    "Ziad@gmail.com",
]

# No pre-installed accounts: users are created only via registration.
CORE_ACCOUNTS = []

ROLE_NAMES = [
    "super_admin",
    "admin",
    "user",
    "doctor",
    "nurse",
    "technician",
    "patient",
    "emergency",
]


DEMO_HOSPITALS = [
    {
        "name": "Ain Shams University Hospital",
        "address": "El-Khalifa El-Ma'moun St., Abbassia, Cairo",
        "phone": "+20224831688",
        "email": "ain-shams@neurobleed.com",
        "license_number": "LIC-EG-CAI-001",
        "hospital_type": HospitalType.TEACHING,
        "latitude": 30.0772,
        "longitude": 31.2854,
    },
    {
        "name": "Kasr El Aini Hospital",
        "address": "Kasr El Aini St., Manial, Cairo",
        "phone": "+20223651234",
        "email": "kasrelaini@neurobleed.com",
        "license_number": "LIC-EG-CAI-002",
        "hospital_type": HospitalType.TEACHING,
        "latitude": 30.0286,
        "longitude": 31.2278,
    },
    {
        "name": "Dar Al Fouad Hospital",
        "address": "Youssef Abbas St., Nasr City, Cairo",
        "phone": "+20233339415",
        "email": "daralfouad@neurobleed.com",
        "license_number": "LIC-EG-CAI-003",
        "hospital_type": HospitalType.GENERAL,
        "latitude": 30.0658,
        "longitude": 31.3196,
    },
    {
        "name": "National Heart Institute",
        "address": "Imam Ali St., Giza",
        "phone": "+20235739555",
        "email": "heart-inst@neurobleed.com",
        "license_number": "LIC-EG-GIZ-004",
        "hospital_type": HospitalType.SPECIALIZED,
        "latitude": 30.0648,
        "longitude": 31.2098,
    },
    {
        "name": "Nasser Institute Hospital",
        "address": "Ramses St., Cairo",
        "phone": "+20225783581",
        "email": "nasser@neurobleed.com",
        "license_number": "LIC-EG-CAI-005",
        "hospital_type": HospitalType.GENERAL,
        "latitude": 30.0536,
        "longitude": 31.2367,
    },
    {
        "name": "Demerdash Hospital",
        "address": "El-Demerdash St., Abbassia, Cairo",
        "phone": "+20226700207",
        "email": "demerdash@neurobleed.com",
        "license_number": "LIC-EG-CAI-006",
        "hospital_type": HospitalType.TEACHING,
        "latitude": 30.0827,
        "longitude": 31.2904,
    },
    {
        "name": "El-Sahel Teaching Hospital",
        "address": "El-Sahel St., Shubra, Cairo",
        "phone": "+20225798611",
        "email": "elsahel@neurobleed.com",
        "license_number": "LIC-EG-CAI-007",
        "hospital_type": HospitalType.GENERAL,
        "latitude": 30.0964,
        "longitude": 31.2468,
    },
    {
        "name": "Sheikh Zayed Specialized Hospital",
        "address": "26th of July Corridor, Sheikh Zayed, Giza",
        "phone": "+20238512101",
        "email": "sheikhzayed@neurobleed.com",
        "license_number": "LIC-EG-GIZ-008",
        "hospital_type": HospitalType.SPECIALIZED,
        "latitude": 30.0281,
        "longitude": 31.0004,
    },
]


async def _seed_roles(session) -> int:
    created = 0
    for name in ROLE_NAMES:
        result = await session.execute(select(Role).where(Role.name == name))
        role = result.scalar_one_or_none()
        if role is None:
            session.add(Role(name=name, description=None, is_system=True))
            print(f"[seed] role created: {name}")
            created += 1
    await session.commit()
    return created


async def _seed_hospitals(session) -> int:
    created = 0
    for entry in DEMO_HOSPITALS:
        result = await session.execute(
            select(Hospital).where(Hospital.email == entry["email"])
        )
        existing = result.scalar_one_or_none()
        if existing is not None:
            print(f"[seed] hospital exists: {entry['name']}")
            continue
        session.add(Hospital(**entry, is_active=True))
        print(f"[seed] hospital created: {entry['name']}")
        created += 1
    await session.commit()
    return created


async def _delete_legacy_demo_users(session) -> int:
    deleted = 0
    for email in LEGACY_DEMO_EMAILS:
        result = await session.execute(select(User.id).where(User.email == email))
        user_ids = [row[0] for row in result.all()]
        for user_id in user_ids:
            await session.execute(delete(User).where(User.id == user_id))
            print(f"[seed] demo account removed: {email}")
            deleted += 1
    await session.commit()
    return deleted


async def _assign_role(session, user: User, role_name: str) -> None:
    result = await session.execute(select(Role).where(Role.name == role_name))
    role = result.scalar_one_or_none()
    if role is None:
        return
    already = await session.execute(
        select(user_role.c.user_id).where(
            user_role.c.user_id == user.id, user_role.c.role_id == role.id
        )
    )
    if already.scalar_one_or_none() is None:
        await session.execute(
            user_role.insert().values(user_id=user.id, role_id=role.id)
        )


async def seed() -> int:
    created = 0
    async with async_session() as session:
        created += await _seed_roles(session)
        created += await _seed_hospitals(session)
        created += await _delete_legacy_demo_users(session)
        await session.commit()
    return created


def main() -> None:
    try:
        asyncio.run(init_db())
        created = asyncio.run(seed())
        print(f"[seed] done. created={created}")
    except Exception as exc:  # noqa: BLE001
        print(f"[seed] ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
