import 'package:shared/shared.dart';

enum Permission {
  patientCreate,
  patientRead,
  patientUpdate,
  patientDelete,
  patientSearch,
  patientExport,
  patientViewSensitive,
  patientTransfer,
  patientMerge,
  patientArchive,
  patientRestore,

  medicalRecordCreate,
  medicalRecordRead,
  medicalRecordUpdate,
  medicalRecordDelete,
  medicalRecordVerify,

  admissionCreate,
  admissionRead,
  admissionUpdate,
  admissionDelete,
  admissionDischarge,
  admissionTransfer,

  noteCreate,
  noteRead,
  noteUpdate,
  noteDelete,
  noteViewConfidential,

  documentCreate,
  documentRead,
  documentUpdate,
  documentDelete,
  documentVerify,
  documentDownload,

  vitalsCreate,
  vitalsRead,
  vitalsUpdate,
  vitalsDelete,
  vitalsExport,

  alertCreate,
  alertRead,
  alertUpdate,
  alertDelete,
  alertAcknowledge,
  alertResolve,
  alertEscalate,

  auditRead,
  auditExport,
  userManage,
  roleManage,
  systemConfig,
}

class RolePermissions {
  static const Map<UserRole, List<Permission>> _permissions = {
    UserRole.admin: [
      Permission.patientCreate,
      Permission.patientRead,
      Permission.patientUpdate,
      Permission.patientDelete,
      Permission.patientSearch,
      Permission.patientExport,
      Permission.patientViewSensitive,
      Permission.patientTransfer,
      Permission.patientMerge,
      Permission.patientArchive,
      Permission.patientRestore,
      Permission.medicalRecordCreate,
      Permission.medicalRecordRead,
      Permission.medicalRecordUpdate,
      Permission.medicalRecordDelete,
      Permission.medicalRecordVerify,
      Permission.admissionCreate,
      Permission.admissionRead,
      Permission.admissionUpdate,
      Permission.admissionDelete,
      Permission.admissionDischarge,
      Permission.admissionTransfer,
      Permission.noteCreate,
      Permission.noteRead,
      Permission.noteUpdate,
      Permission.noteDelete,
      Permission.noteViewConfidential,
      Permission.documentCreate,
      Permission.documentRead,
      Permission.documentUpdate,
      Permission.documentDelete,
      Permission.documentVerify,
      Permission.documentDownload,
      Permission.vitalsCreate,
      Permission.vitalsRead,
      Permission.vitalsUpdate,
      Permission.vitalsDelete,
      Permission.vitalsExport,
      Permission.alertCreate,
      Permission.alertRead,
      Permission.alertUpdate,
      Permission.alertDelete,
      Permission.alertAcknowledge,
      Permission.alertResolve,
      Permission.alertEscalate,
      Permission.auditRead,
      Permission.auditExport,
      Permission.userManage,
      Permission.roleManage,
      Permission.systemConfig,
    ],
    UserRole.doctor: [
      Permission.patientCreate,
      Permission.patientRead,
      Permission.patientUpdate,
      Permission.patientSearch,
      Permission.patientExport,
      Permission.patientViewSensitive,
      Permission.patientTransfer,
      Permission.medicalRecordCreate,
      Permission.medicalRecordRead,
      Permission.medicalRecordUpdate,
      Permission.medicalRecordVerify,
      Permission.admissionCreate,
      Permission.admissionRead,
      Permission.admissionUpdate,
      Permission.admissionDischarge,
      Permission.admissionTransfer,
      Permission.noteCreate,
      Permission.noteRead,
      Permission.noteUpdate,
      Permission.noteViewConfidential,
      Permission.documentCreate,
      Permission.documentRead,
      Permission.documentUpdate,
      Permission.documentVerify,
      Permission.documentDownload,
      Permission.vitalsCreate,
      Permission.vitalsRead,
      Permission.vitalsExport,
      Permission.alertCreate,
      Permission.alertRead,
      Permission.alertAcknowledge,
      Permission.alertResolve,
      Permission.alertEscalate,
      Permission.auditRead,
    ],
    UserRole.nurse: [
      Permission.patientRead,
      Permission.patientUpdate,
      Permission.patientSearch,
      Permission.patientViewSensitive,
      Permission.medicalRecordRead,
      Permission.medicalRecordUpdate,
      Permission.admissionRead,
      Permission.admissionUpdate,
      Permission.noteCreate,
      Permission.noteRead,
      Permission.noteUpdate,
      Permission.documentCreate,
      Permission.documentRead,
      Permission.documentDownload,
      Permission.vitalsCreate,
      Permission.vitalsRead,
      Permission.vitalsUpdate,
      Permission.alertCreate,
      Permission.alertRead,
      Permission.alertAcknowledge,
    ],
    UserRole.researcher: [
      Permission.patientRead,
      Permission.patientSearch,
      Permission.patientExport,
      Permission.medicalRecordRead,
      Permission.noteRead,
      Permission.documentRead,
      Permission.documentDownload,
      Permission.vitalsRead,
      Permission.vitalsExport,
      Permission.alertRead,
      Permission.auditRead,
    ],
    UserRole.family: [
      Permission.patientRead,
      Permission.medicalRecordRead,
      Permission.noteRead,
    ],
    UserRole.emergency: [
      Permission.patientCreate,
      Permission.patientRead,
      Permission.patientSearch,
      Permission.patientViewSensitive,
      Permission.medicalRecordRead,
      Permission.admissionCreate,
      Permission.admissionRead,
      Permission.noteCreate,
      Permission.noteRead,
      Permission.vitalsRead,
      Permission.alertRead,
      Permission.alertAcknowledge,
    ],
  };

  static bool hasPermission(UserRole role, Permission permission) {
    return _permissions[role]?.contains(permission) ?? false;
  }

  static List<Permission> getPermissions(UserRole role) {
    return _permissions[role] ?? [];
  }

  static bool canAccessPatient(UserRole role,
      {String? patientId, String? userId}) {
    return hasPermission(role, Permission.patientRead);
  }
}

class SensitiveDataFilter {
  static List<String> sensitiveFields = [
    'nationalId',
    'email',
    'phone',
    'phoneSecondary',
    'address',
    'insuranceId',
    'insurancePolicyNumber',
    'employer',
    'occupation',
  ];

  static Map<String, dynamic> filterPatientData(
    Map<String, dynamic> patientData,
    UserRole role,
  ) {
    if (role == UserRole.admin || role == UserRole.doctor) {
      return patientData;
    }
    final filtered = Map<String, dynamic>.from(patientData);
    for (final field in sensitiveFields) {
      if (role != UserRole.nurse && role != UserRole.emergency) {
        filtered.remove(field);
      }
    }
    return filtered;
  }
}
