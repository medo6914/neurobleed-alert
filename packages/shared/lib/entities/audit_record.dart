import 'package:equatable/equatable.dart';

class AuditRecord extends Equatable {
  final String id;
  final String patientId;
  final String? userId;
  final String? userName;
  final String? userRole;
  final String action;
  final String resourceType;
  final String? resourceId;
  final Map<String, dynamic>? changes;
  final String? ipAddress;
  final String? userAgent;
  final String? details;
  final DateTime timestamp;
  final DateTime createdAt;

  const AuditRecord({
    required this.id,
    required this.patientId,
    this.userId,
    this.userName,
    this.userRole,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.changes,
    this.ipAddress,
    this.userAgent,
    this.details,
    required this.timestamp,
    required this.createdAt,
  });

  AuditRecord copyWith({
    String? id,
    String? patientId,
    String? userId,
    String? userName,
    String? userRole,
    String? action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? changes,
    String? ipAddress,
    String? userAgent,
    String? details,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return AuditRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      changes: changes ?? this.changes,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AuditRecord.fromJson(Map<String, dynamic> json) {
    return AuditRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userRole: json['userRole'] as String?,
      action: json['action'] as String,
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as String?,
      changes: json['changes'] as Map<String, dynamic>?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      details: json['details'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'changes': changes,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, action, resourceType, timestamp];
}
