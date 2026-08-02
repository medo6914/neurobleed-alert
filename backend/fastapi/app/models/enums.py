import enum


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    DOCTOR = "doctor"
    NURSE = "nurse"
    TECHNICIAN = "technician"
    PATIENT = "patient"
    EMERGENCY = "emergency"


class Gender(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class BloodType(str, enum.Enum):
    A_POSITIVE = "A+"
    A_NEGATIVE = "A-"
    B_POSITIVE = "B+"
    B_NEGATIVE = "B-"
    AB_POSITIVE = "AB+"
    AB_NEGATIVE = "AB-"
    O_POSITIVE = "O+"
    O_NEGATIVE = "O-"


class RiskLevel(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"
    UNKNOWN = "unknown"


class Severity(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class AlertType(str, enum.Enum):
    ICP_ELEVATED = "icp_elevated"
    DESATURATION = "desaturation"
    BRADYCARDIA = "bradycardia"
    TACHYCARDIA = "tachycardia"
    HYPOTENSION = "hypotension"
    HYPERTENSION = "hypertension"
    ARRHYTHMIA = "arrhythmia"
    SYSTEM = "system"
    GENERAL = "general"


class DeviceType(str, enum.Enum):
    NB_01 = "NB-01"
    NB_02 = "NB-02"


class DeviceStatus(str, enum.Enum):
    ONLINE = "online"
    OFFLINE = "offline"
    ERROR = "error"
    MAINTENANCE = "maintenance"
    SLEEPING = "sleeping"
    UPDATING = "updating"


class ReportType(str, enum.Enum):
    RISK_ASSESSMENT = "risk_assessment"
    BLEEDING_DETECTION = "bleeding_detection"
    ICP_PREDICTION = "icp_prediction"
    HERNIATION_PREDICTION = "herniation_prediction"


class ICPRisk(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class HerniationRisk(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class HospitalType(str, enum.Enum):
    GENERAL = "general"
    SPECIALIZED = "specialized"
    TEACHING = "teaching"
    CLINIC = "clinic"
    RESEARCH = "research"


class OrganizationType(str, enum.Enum):
    HOSPITAL = "hospital"
    CLINIC = "clinic"
    RESEARCH_CENTER = "research_center"
    GOVERNMENT = "government"
    INSURANCE = "insurance"
    PHARMA = "pharma"


class KnowledgeUpdateAction(str, enum.Enum):
    CREATE = "create"
    UPDATE = "update"
    DELETE = "delete"
    PUBLISH = "publish"
    UNPUBLISH = "unpublish"


class ReportFormat(str, enum.Enum):
    PDF = "pdf"
    HTML = "html"
    DOCX = "docx"


class ReportStatus(str, enum.Enum):
    PENDING = "pending"
    GENERATING = "generating"
    COMPLETED = "completed"
    FAILED = "failed"


class EmergencyEventStatus(str, enum.Enum):
    TRIGGERED = "triggered"
    CONTACTING = "contacting"
    ACKNOWLEDGED = "acknowledged"
    ESCALATED = "escalated"
    RESOLVED = "resolved"


class TicketStatus(str, enum.Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    RESOLVED = "resolved"
    CLOSED = "closed"


class TicketPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class SubscriptionTier(str, enum.Enum):
    FREE = "free"
    BASIC = "basic"
    PROFESSIONAL = "professional"
    ENTERPRISE = "enterprise"


class SubscriptionStatus(str, enum.Enum):
    ACTIVE = "active"
    PAST_DUE = "past_due"
    CANCELED = "canceled"
    EXPIRED = "expired"


class ProvisioningKeyStatus(str, enum.Enum):
    ACTIVE = "active"
    USED = "used"
    EXPIRED = "expired"
    REVOKED = "revoked"


class DeviceEventType(str, enum.Enum):
    REGISTERED = "registered"
    ASSIGNED = "assigned"
    UNASSIGNED = "unassigned"
    PROVISIONED = "provisioned"
    OTA_STARTED = "ota_started"
    OTA_COMPLETED = "ota_completed"
    OTA_FAILED = "ota_failed"
    HEARTBEAT_LOST = "heartbeat_lost"
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    ERROR = "error"
    DIAGNOSTIC_REPORTED = "diagnostic_reported"
