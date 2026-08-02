from datetime import datetime, date
from uuid import UUID

from pydantic import BaseModel


class AnalyticsOverview(BaseModel):
    total_patients: int
    active_patients: int
    total_devices: int
    online_devices: int
    total_alerts: int
    critical_alerts: int
    total_hospitals: int
    total_users: int
    reports_generated: int
    bed_occupancy_rate: float


class PatientAnalytics(BaseModel):
    total: int
    active: int
    admitted_today: int
    discharged_today: int
    male: int
    female: int
    average_age: float
    average_length_of_stay_days: float
    admissions_by_month: list[dict]
    discharges_by_month: list[dict]
    by_department: list[dict]


class DeviceAnalytics(BaseModel):
    total: int
    online: int
    offline: int
    error: int
    maintenance: int
    sleeping: int
    updating: int
    average_battery: float
    low_battery_count: int
    by_type: list[dict]
    by_status: list[dict]


class AlertAnalytics(BaseModel):
    total: int
    critical: int
    high: int
    medium: int
    low: int
    unacknowledged: int
    average_response_time_minutes: float
    by_type: list[dict]
    by_severity: list[dict]
    by_day: list[dict]


class HospitalMetrics(BaseModel):
    id: UUID
    name: str
    patient_count: int
    device_count: int
    active_alerts: int
    bed_capacity: int
    bed_occupancy: float
    alert_trend: list[dict]


class HospitalOverview(BaseModel):
    total_hospitals: int
    total_beds: int
    occupied_beds: int
    hospitals: list[HospitalMetrics]


class SystemHealth(BaseModel):
    total_requests_24h: int
    active_web_sockets: int
    avg_response_time_ms: float
    error_rate_24h: float
    database_connections: int
    cache_hit_rate: float
    uptime_hours: float
    recent_errors: list[dict]
    service_status: list[dict]


class ActivityFeedItem(BaseModel):
    id: UUID
    event_type: str
    description: str
    entity_type: str
    entity_id: UUID | None
    user_name: str | None
    timestamp: datetime
    metadata: dict | None
