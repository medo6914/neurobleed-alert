import 'package:equatable/equatable.dart';

class HospitalAssignment extends Equatable {
  final String id;
  final String patientId;
  final String hospitalId;
  final String? hospitalName;
  final String? departmentId;
  final String? departmentName;
  final bool isPrimary;
  final DateTime assignedAt;
  final String? assignedBy;
  final DateTime? unassignedAt;
  final String? reason;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HospitalAssignment({
    required this.id,
    required this.patientId,
    required this.hospitalId,
    this.hospitalName,
    this.departmentId,
    this.departmentName,
    this.isPrimary = false,
    required this.assignedAt,
    this.assignedBy,
    this.unassignedAt,
    this.reason,
    required this.createdAt,
    required this.updatedAt,
  });

  HospitalAssignment copyWith({
    String? id,
    String? patientId,
    String? hospitalId,
    String? hospitalName,
    String? departmentId,
    String? departmentName,
    bool? isPrimary,
    DateTime? assignedAt,
    String? assignedBy,
    DateTime? unassignedAt,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HospitalAssignment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      isPrimary: isPrimary ?? this.isPrimary,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      unassignedAt: unassignedAt ?? this.unassignedAt,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory HospitalAssignment.fromJson(Map<String, dynamic> json) {
    return HospitalAssignment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      hospitalId: json['hospitalId'] as String,
      hospitalName: json['hospitalName'] as String?,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      assignedBy: json['assignedBy'] as String?,
      unassignedAt: json['unassignedAt'] != null ? DateTime.parse(json['unassignedAt'] as String) : null,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'isPrimary': isPrimary,
      'assignedAt': assignedAt.toIso8601String(),
      'assignedBy': assignedBy,
      'unassignedAt': unassignedAt?.toIso8601String(),
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, hospitalId, isPrimary, assignedAt];
}
