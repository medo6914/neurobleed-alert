import 'package:equatable/equatable.dart';

enum AdmissionStatus { scheduled, active, discharged, transferred, cancelled }

class Admission extends Equatable {
  final String id;
  final String patientId;
  final String? patientName;
  final String? patientMrn;
  final String? hospitalId;
  final String? hospitalName;
  final String? departmentId;
  final String? departmentName;
  final String? ward;
  final String? bedNumber;
  final AdmissionStatus status;
  final String? admissionType;
  final DateTime admissionDate;
  final DateTime? dischargeDate;
  final String? admittingPhysician;
  final String? admittingPhysicianId;
  final String? dischargingPhysician;
  final String? dischargingPhysicianId;
  final String? primaryDiagnosis;
  final String? admissionNotes;
  final String? dischargeSummary;
  final String? dischargeDisposition;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Admission({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientMrn,
    this.hospitalId,
    this.hospitalName,
    this.departmentId,
    this.departmentName,
    this.ward,
    this.bedNumber,
    this.status = AdmissionStatus.active,
    this.admissionType,
    required this.admissionDate,
    this.dischargeDate,
    this.admittingPhysician,
    this.admittingPhysicianId,
    this.dischargingPhysician,
    this.dischargingPhysicianId,
    this.primaryDiagnosis,
    this.admissionNotes,
    this.dischargeSummary,
    this.dischargeDisposition,
    required this.createdAt,
    required this.updatedAt,
  });

  Admission copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientMrn,
    String? hospitalId,
    String? hospitalName,
    String? departmentId,
    String? departmentName,
    String? ward,
    String? bedNumber,
    AdmissionStatus? status,
    String? admissionType,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? admittingPhysician,
    String? admittingPhysicianId,
    String? dischargingPhysician,
    String? dischargingPhysicianId,
    String? primaryDiagnosis,
    String? admissionNotes,
    String? dischargeSummary,
    String? dischargeDisposition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Admission(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientMrn: patientMrn ?? this.patientMrn,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      ward: ward ?? this.ward,
      bedNumber: bedNumber ?? this.bedNumber,
      status: status ?? this.status,
      admissionType: admissionType ?? this.admissionType,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      admittingPhysician: admittingPhysician ?? this.admittingPhysician,
      admittingPhysicianId: admittingPhysicianId ?? this.admittingPhysicianId,
      dischargingPhysician: dischargingPhysician ?? this.dischargingPhysician,
      dischargingPhysicianId: dischargingPhysicianId ?? this.dischargingPhysicianId,
      primaryDiagnosis: primaryDiagnosis ?? this.primaryDiagnosis,
      admissionNotes: admissionNotes ?? this.admissionNotes,
      dischargeSummary: dischargeSummary ?? this.dischargeSummary,
      dischargeDisposition: dischargeDisposition ?? this.dischargeDisposition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Admission.fromJson(Map<String, dynamic> json) {
    return Admission(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String?,
      patientMrn: json['patientMrn'] as String?,
      hospitalId: json['hospitalId'] as String?,
      hospitalName: json['hospitalName'] as String?,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      ward: json['ward'] as String?,
      bedNumber: json['bedNumber'] as String?,
      status: json['status'] != null
          ? AdmissionStatus.values.firstWhere((e) => e.name == json['status'])
          : AdmissionStatus.active,
      admissionType: json['admissionType'] as String?,
      admissionDate: DateTime.parse(json['admissionDate'] as String),
      dischargeDate: json['dischargeDate'] != null ? DateTime.parse(json['dischargeDate'] as String) : null,
      admittingPhysician: json['admittingPhysician'] as String?,
      admittingPhysicianId: json['admittingPhysicianId'] as String?,
      dischargingPhysician: json['dischargingPhysician'] as String?,
      dischargingPhysicianId: json['dischargingPhysicianId'] as String?,
      primaryDiagnosis: json['primaryDiagnosis'] as String?,
      admissionNotes: json['admissionNotes'] as String?,
      dischargeSummary: json['dischargeSummary'] as String?,
      dischargeDisposition: json['dischargeDisposition'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientMrn': patientMrn,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'ward': ward,
      'bedNumber': bedNumber,
      'status': status.name,
      'admissionType': admissionType,
      'admissionDate': admissionDate.toIso8601String(),
      'dischargeDate': dischargeDate?.toIso8601String(),
      'admittingPhysician': admittingPhysician,
      'admittingPhysicianId': admittingPhysicianId,
      'dischargingPhysician': dischargingPhysician,
      'dischargingPhysicianId': dischargingPhysicianId,
      'primaryDiagnosis': primaryDiagnosis,
      'admissionNotes': admissionNotes,
      'dischargeSummary': dischargeSummary,
      'dischargeDisposition': dischargeDisposition,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, status, admissionDate];
}
