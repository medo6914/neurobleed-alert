from enum import Enum
from functools import lru_cache


class Permission(str, Enum):
    PATIENT_LIST = "patient:list"
    PATIENT_VIEW = "patient:view"
    PATIENT_CREATE = "patient:create"
    PATIENT_UPDATE = "patient:update"
    PATIENT_DELETE = "patient:delete"

    DEVICE_LIST = "device:list"
    DEVICE_VIEW = "device:view"
    DEVICE_CREATE = "device:create"
    DEVICE_UPDATE = "device:update"
    DEVICE_DELETE = "device:delete"

    MONITORING_VIEW = "monitoring:view"

    ALERT_LIST = "alert:list"
    ALERT_VIEW = "alert:view"
    ALERT_CREATE = "alert:create"
    ALERT_UPDATE = "alert:update"
    ALERT_ACKNOWLEDGE = "alert:acknowledge"

    REPORT_VIEW = "report:view"
    REPORT_CREATE = "report:create"

    USER_LIST = "user:list"
    USER_CREATE = "user:create"
    USER_MANAGE = "user:manage"

    ADMIN_ACCESS = "admin:access"

    SETTINGS_VIEW = "settings:view"
    SETTINGS_UPDATE = "settings:update"

    AI_ASSESS = "ai:assess"
    AI_VIEW = "ai:view"
    AI_MANAGE = "ai:manage"


@lru_cache
def _get_role_permissions() -> dict[str, set[Permission]]:
    return {
        "admin": set(Permission),
        "doctor": {
            Permission.PATIENT_LIST,
            Permission.PATIENT_VIEW,
            Permission.PATIENT_CREATE,
            Permission.PATIENT_UPDATE,
            Permission.DEVICE_LIST,
            Permission.DEVICE_VIEW,
            Permission.MONITORING_VIEW,
            Permission.ALERT_LIST,
            Permission.ALERT_ACKNOWLEDGE,
            Permission.REPORT_VIEW,
            Permission.REPORT_CREATE,
            Permission.USER_LIST,
            Permission.AI_ASSESS,
            Permission.AI_VIEW,
            Permission.ALERT_VIEW,
            Permission.ALERT_CREATE,
            Permission.ALERT_UPDATE,
        },
        "nurse": {
            Permission.PATIENT_LIST,
            Permission.PATIENT_VIEW,
            Permission.MONITORING_VIEW,
            Permission.ALERT_LIST,
            Permission.ALERT_VIEW,
            Permission.ALERT_ACKNOWLEDGE,
        },
        "technician": {
            Permission.DEVICE_LIST,
            Permission.DEVICE_VIEW,
            Permission.DEVICE_CREATE,
            Permission.DEVICE_UPDATE,
            Permission.MONITORING_VIEW,
        },
        "patient": set(),
        "emergency": {
            Permission.PATIENT_VIEW,
            Permission.MONITORING_VIEW,
            Permission.ALERT_LIST,
            Permission.ALERT_VIEW,
        },
    }


def has_permission(role: str, permission: Permission) -> bool:
    permissions = _get_role_permissions().get(role, set())
    return permission in permissions


def get_role_permissions(role: str) -> set[Permission]:
    return _get_role_permissions().get(role, set())


def require_any_permission(*permissions: Permission):
    async def permission_checker(
        current_user,
    ):
        user_permissions = _get_role_permissions().get(current_user.role, set())
        for permission in permissions:
            if permission in user_permissions:
                return current_user
        raise PermissionError(
            f"None of the required permissions granted: {[p.value for p in permissions]}"
        )

    return permission_checker
