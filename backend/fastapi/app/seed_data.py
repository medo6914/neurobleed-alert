"""Seed demo users and hospitals for the graduation presentation.

Creates (idempotently) the three demo accounts:

- admin@neurobleed.com  / Admin123!   (role: admin)
- doctor@neurobleed.com / Doctor123!  (role: doctor)
- patient@neurobleed.com / Patient123! (role: patient)

And a set of real Cairo hospitals with OSM coordinates for the map feature.

Usage:
    python -m app.seed_data
"""

import asyncio
import sys
from datetime import datetime, timezone

from sqlalchemy import select

from app.core.security import hash_password
from app.database import async_session, init_db
from app.models.enums import UserRole, HospitalType
from app.models.hospital import Hospital
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
        created += await _seed_hospitals(session)
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
        asyncio.run(init_db())
        created = asyncio.run(seed())
        print(f"[seed] done. created={created}")
    except Exception as exc:  # noqa: BLE001
        print(f"[seed] ERROR: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
