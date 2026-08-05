import logging
import json
from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.patient import Patient
from app.models.device import Device
from app.models.alert import Alert
from app.models.hospital import Hospital
from app.models.user import User
from app.models.audit_log import AuditLog
from app.models.clinical_report import ClinicalReport
from app.models.enums import DeviceStatus, Severity, Gender
from app.schemas.analytics import (
    AnalyticsOverview,
    PatientAnalytics,
    DeviceAnalytics,
    AlertAnalytics,
    HospitalOverview,
    HospitalMetrics,
    SystemHealth,
    ActivityFeedItem,
)

logger = logging.getLogger(__name__)


class AnalyticsService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_overview(self, hospital_id: UUID | None = None) -> AnalyticsOverview:
        patient_q = select(func.count(Patient.id))
        active_q = select(func.count(Patient.id)).where(Patient.is_active == True)
        device_q = select(func.count(Device.id))
        online_q = select(func.count(Device.id)).where(
            Device.status == DeviceStatus.ONLINE
        )
        alert_q = select(func.count(Alert.id)).where(Alert.is_deleted == False)
        critical_q = select(func.count(Alert.id)).where(
            Alert.severity == Severity.CRITICAL, Alert.is_deleted == False
        )
        hosp_q = select(func.count(Hospital.id)).where(Hospital.is_deleted == False)
        user_q = select(func.count(User.id))
        report_q = select(func.count(ClinicalReport.id)).where(
            ClinicalReport.is_deleted == False
        )

        if hospital_id:
            patient_q = patient_q.where(Patient.hospital_id == hospital_id)
            active_q = active_q.where(Patient.hospital_id == hospital_id)
            device_q = device_q.where(Device.hospital_id == hospital_id)
            online_q = online_q.where(Device.hospital_id == hospital_id)

        total_patients = (await self.db.scalar(patient_q)) or 0
        active_patients = (await self.db.scalar(active_q)) or 0
        total_devices = (await self.db.scalar(device_q)) or 0
        online_devices = (await self.db.scalar(online_q)) or 0
        total_alerts = (await self.db.scalar(alert_q)) or 0
        critical_alerts = (await self.db.scalar(critical_q)) or 0
        total_hospitals = (await self.db.scalar(hosp_q)) or 0
        total_users = (await self.db.scalar(user_q)) or 0
        reports_generated = (await self.db.scalar(report_q)) or 0

        bed_count = 0
        occupied = 0
        if hospital_id:
            h_result = await self.db.execute(
                select(func.count(Hospital.id)).where(
                    Hospital.id == hospital_id, Hospital.is_deleted == False
                )
            )
            bed_count = h_result.scalar() or 0
            occupied = min(active_patients, bed_count) if bed_count else 0
        else:
            bed_count = total_hospitals
            occupied = active_patients if bed_count else 0

        occupancy = (occupied / bed_count * 100) if bed_count > 0 else 0.0

        return AnalyticsOverview(
            total_patients=total_patients,
            active_patients=active_patients,
            total_devices=total_devices,
            online_devices=online_devices,
            total_alerts=total_alerts,
            critical_alerts=critical_alerts,
            total_hospitals=total_hospitals,
            total_users=total_users,
            reports_generated=reports_generated,
            bed_occupancy_rate=round(occupancy, 1),
        )

    async def get_patient_analytics(
        self, hospital_id: UUID | None = None
    ) -> PatientAnalytics:
        base = select(Patient)
        if hospital_id:
            base = base.where(Patient.hospital_id == hospital_id)

        total = (
            await self.db.scalar(select(func.count()).select_from(base.subquery()))
        ) or 0
        active = (
            await self.db.scalar(
                select(func.count()).select_from(
                    base.where(Patient.is_active == True).subquery()
                )
            )
        ) or 0

        today = datetime.now(timezone.utc).date()
        today_start = datetime.combine(today, datetime.min.time(), tzinfo=timezone.utc)
        today_end = datetime.combine(today, datetime.max.time(), tzinfo=timezone.utc)

        q = base
        if hospital_id:
            q = q.where(Patient.hospital_id == hospital_id)
        admitted_today = (
            await self.db.scalar(
                select(func.count()).select_from(
                    q.where(
                        Patient.admission_date >= today_start,
                        Patient.admission_date <= today_end,
                    ).subquery()
                )
            )
        ) or 0

        q = base
        if hospital_id:
            q = q.where(Patient.hospital_id == hospital_id)
        discharged_today = (
            await self.db.scalar(
                select(func.count()).select_from(
                    q.where(
                        Patient.discharge_date >= today_start,
                        Patient.discharge_date <= today_end,
                    ).subquery()
                )
            )
        ) or 0

        male = 0
        female = 0
        result = await self.db.execute(
            select(Patient.gender, func.count(Patient.id)).group_by(Patient.gender)
        )
        for gender, count in result:
            if gender == Gender.MALE:
                male = count
            elif gender == Gender.FEMALE:
                female = count

        now = datetime.now(timezone.utc)
        six_months_ago = now - timedelta(days=180)

        all_patients_result = await self.db.execute(base)
        all_patients = all_patients_result.scalars().all()

        total_birth_years = 0
        birth_year_count = 0
        for p in all_patients:
            if p.date_of_birth:
                try:
                    dob = p.date_of_birth
                    if hasattr(dob, "year"):
                        total_birth_years += now.year - dob.year
                        birth_year_count += 1
                except (ValueError, TypeError):
                    pass
        avg_age = (
            round(total_birth_years / birth_year_count, 1) if birth_year_count else 0.0
        )

        total_los = 0.0
        los_count = 0
        for p in all_patients:
            if p.admission_date and p.discharge_date:
                delta = p.discharge_date - p.admission_date
                if hasattr(delta, "days"):
                    total_los += delta.days
                    los_count += 1
        avg_los = round(total_los / los_count, 1) if los_count else 0.0

        admissions_by_month = {}
        discharges_by_month = {}
        for p in all_patients:
            if p.admission_date and p.admission_date >= six_months_ago:
                key = p.admission_date.strftime("%Y-%m")
                admissions_by_month[key] = admissions_by_month.get(key, 0) + 1
            if p.discharge_date and p.discharge_date >= six_months_ago:
                key = p.discharge_date.strftime("%Y-%m")
                discharges_by_month[key] = discharges_by_month.get(key, 0) + 1

        admissions_by_month_list = sorted(
            [{"month": k, "count": v} for k, v in admissions_by_month.items()],
            key=lambda x: x["month"],
        )
        discharges_by_month_list = sorted(
            [{"month": k, "count": v} for k, v in discharges_by_month.items()],
            key=lambda x: x["month"],
        )

        q = base.where(Patient.department.isnot(None))
        result = await self.db.execute(
            select(Patient.department, func.count(Patient.id)).group_by(
                Patient.department
            )
        )
        by_department = [{"department": r[0], "count": r[1]} for r in result]

        return PatientAnalytics(
            total=total,
            active=active,
            admitted_today=admitted_today,
            discharged_today=discharged_today,
            male=male,
            female=female,
            average_age=avg_age,
            average_length_of_stay_days=avg_los,
            admissions_by_month=admissions_by_month_list,
            discharges_by_month=discharges_by_month_list,
            by_department=by_department,
        )

    async def get_device_analytics(
        self, hospital_id: UUID | None = None
    ) -> DeviceAnalytics:
        base = select(Device)
        if hospital_id:
            base = base.where(Device.hospital_id == hospital_id)

        total = (
            await self.db.scalar(select(func.count()).select_from(base.subquery()))
        ) or 0
        counts = {s: 0 for s in DeviceStatus}
        result = await self.db.execute(
            select(Device.status, func.count(Device.id)).group_by(Device.status)
        )
        for status, count in result:
            counts[status] = count

        avg_battery = (
            await self.db.scalar(select(func.avg(Device.battery_level)))
        ) or 0.0
        low_battery = (
            await self.db.scalar(
                select(func.count()).select_from(
                    base.where(Device.battery_level < 20).subquery()
                )
            )
        ) or 0

        result = await self.db.execute(
            select(Device.device_type, func.count(Device.id)).group_by(
                Device.device_type
            )
        )
        by_type = [
            {"type": r[0].value if hasattr(r[0], "value") else str(r[0]), "count": r[1]}
            for r in result
        ]

        result = await self.db.execute(
            select(Device.status, func.count(Device.id)).group_by(Device.status)
        )
        by_status = [
            {
                "status": r[0].value if hasattr(r[0], "value") else str(r[0]),
                "count": r[1],
            }
            for r in result
        ]

        return DeviceAnalytics(
            total=total,
            online=counts[DeviceStatus.ONLINE],
            offline=counts[DeviceStatus.OFFLINE],
            error=counts[DeviceStatus.ERROR],
            maintenance=counts[DeviceStatus.MAINTENANCE],
            sleeping=counts[DeviceStatus.SLEEPING],
            updating=counts[DeviceStatus.UPDATING],
            average_battery=round(float(avg_battery), 1),
            low_battery_count=low_battery,
            by_type=by_type,
            by_status=by_status,
        )

    async def get_alert_analytics(
        self, hospital_id: UUID | None = None
    ) -> AlertAnalytics:
        base = select(Alert).where(Alert.is_deleted == False)
        if hospital_id:
            base = base.where(Alert.hospital_id == hospital_id)

        total = (
            await self.db.scalar(select(func.count()).select_from(base.subquery()))
        ) or 0
        severity_counts = {s: 0 for s in Severity}
        result = await self.db.execute(
            select(Alert.severity, func.count(Alert.id)).group_by(Alert.severity)
        )
        for severity, count in result:
            severity_counts[severity] = count

        unacknowledged = (
            await self.db.scalar(
                select(func.count()).select_from(
                    base.where(Alert.acknowledged_at.is_(None)).subquery()
                )
            )
        ) or 0

        result = await self.db.execute(
            select(Alert.alert_type, func.count(Alert.id)).group_by(Alert.alert_type)
        )
        by_type = [
            {"type": r[0].value if hasattr(r[0], "value") else str(r[0]), "count": r[1]}
            for r in result
        ]

        result = await self.db.execute(
            select(Alert.severity, func.count(Alert.id)).group_by(Alert.severity)
        )
        by_severity = [
            {
                "severity": r[0].value if hasattr(r[0], "value") else str(r[0]),
                "count": r[1],
            }
            for r in result
        ]

        now = datetime.now(timezone.utc)
        seven_days_ago = now - timedelta(days=7)
        recent_alerts = await self.db.execute(
            select(Alert)
            .where(Alert.created_at >= seven_days_ago, Alert.is_deleted == False)
            .order_by(Alert.created_at)
        )
        by_day_map = {}
        for a in recent_alerts.scalars().all():
            if a.created_at:
                key = a.created_at.strftime("%Y-%m-%d")
                by_day_map[key] = by_day_map.get(key, 0) + 1
        by_day = [{"date": k, "count": v} for k, v in sorted(by_day_map.items())]

        avg_response = 0.0
        result = await self.db.execute(
            select(
                func.avg(
                    func.extract("epoch", Alert.acknowledged_at - Alert.created_at) / 60
                )
            ).where(Alert.acknowledged_at.isnot(None), Alert.created_at.isnot(None))
        )
        avg_val = result.scalar()
        if avg_val:
            avg_response = round(float(avg_val), 1)

        return AlertAnalytics(
            total=total,
            critical=severity_counts[Severity.CRITICAL],
            high=severity_counts[Severity.HIGH],
            medium=severity_counts[Severity.MEDIUM],
            low=severity_counts[Severity.LOW],
            unacknowledged=unacknowledged,
            average_response_time_minutes=avg_response,
            by_type=by_type,
            by_severity=by_severity,
            by_day=by_day,
        )

    async def get_hospital_overview(self) -> HospitalOverview:
        result = await self.db.execute(
            select(Hospital).where(Hospital.is_deleted == False)
        )
        hospitals = result.scalars().all()

        metrics = []
        total_beds = 0
        occupied_beds = 0
        for h in hospitals:
            p_count = (
                await self.db.scalar(
                    select(func.count(Patient.id)).where(Patient.hospital_id == h.id)
                )
            ) or 0
            d_count = (
                await self.db.scalar(
                    select(func.count(Device.id)).where(Device.hospital_id == h.id)
                )
            ) or 0
            a_count = (
                await self.db.scalar(
                    select(func.count(Alert.id)).where(
                        Alert.hospital_id == h.id, Alert.is_deleted == False
                    )
                )
            ) or 0

            beds = h.bed_count or 0
            total_beds += beds
            occ = min(p_count, beds) if beds else 0
            occupied_beds += occ

            metrics.append(
                HospitalMetrics(
                    id=h.id,
                    name=h.name or "Unnamed",
                    patient_count=p_count,
                    device_count=d_count,
                    active_alerts=a_count,
                    bed_capacity=beds,
                    bed_occupancy=round((occ / beds * 100) if beds else 0, 1),
                    alert_trend=[],
                )
            )

        return HospitalOverview(
            total_hospitals=len(hospitals),
            total_beds=total_beds,
            occupied_beds=occupied_beds,
            hospitals=metrics,
        )

    async def get_system_health(self) -> SystemHealth:
        now = datetime.now(timezone.utc)
        yesterday = now - timedelta(hours=24)

        recent_logs_q = select(func.count(AuditLog.id)).where(
            AuditLog.created_at >= yesterday
        )
        total_requests = (await self.db.scalar(recent_logs_q)) or 0

        error_q = select(func.count(AuditLog.id)).where(
            AuditLog.created_at >= yesterday,
            AuditLog.action.ilike("%error%"),
        )
        errors_24h = (await self.db.scalar(error_q)) or 0
        error_rate = (
            round(errors_24h / total_requests * 100, 2) if total_requests else 0.0
        )

        recent_errors = []
        error_logs = await self.db.execute(
            select(AuditLog)
            .where(
                AuditLog.created_at >= yesterday,
                AuditLog.action.ilike("%error%"),
            )
            .order_by(AuditLog.created_at.desc())
            .limit(20)
        )
        for log in error_logs.scalars().all():
            recent_errors.append(
                {
                    "id": str(log.id),
                    "action": log.action,
                    "details": log.details,
                    "timestamp": log.created_at.isoformat() if log.created_at else None,
                }
            )

        return SystemHealth(
            total_requests_24h=total_requests,
            active_web_sockets=0,
            avg_response_time_ms=0.0,
            error_rate_24h=error_rate,
            database_connections=0,
            cache_hit_rate=0.0,
            uptime_hours=0.0,
            recent_errors=recent_errors,
            service_status=[
                {"name": "API Server", "status": "healthy", "uptime": "0"},
                {"name": "Database", "status": "healthy", "uptime": "0"},
                {"name": "Redis Cache", "status": "degraded", "uptime": "0"},
            ],
        )

    async def get_activity_feed(self, limit: int = 50) -> list[ActivityFeedItem]:
        result = await self.db.execute(
            select(AuditLog, User)
            .outerjoin(User, User.id == AuditLog.user_id)
            .order_by(AuditLog.created_at.desc())
            .limit(limit)
        )
        items = []
        for log, user in result.all():
            details = log.details
            if isinstance(details, dict):
                details = json.dumps(details, ensure_ascii=False)
            items.append(
                ActivityFeedItem(
                    id=log.id,
                    event_type=log.action,
                    description=details or log.action,
                    entity_type=log.resource or "unknown",
                    entity_id=log.resource_id,
                    user_name=user.full_name if user else None,
                    timestamp=log.created_at,
                    metadata={"ip": log.ip_address} if log.ip_address else None,
                )
            )
        return items
