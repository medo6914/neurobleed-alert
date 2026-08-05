import 'package:equatable/equatable.dart';

enum AlertStatus { active, acknowledged, resolved, escalated, falseAlarm }

class AlertRecord extends Equatable {
  final String id;
  final String patientId;
  final String? patientName;
  final String? deviceId;
  final String title;
  final String description;
  final String level;
  final String category;
  final double? riskScore;
  final AlertStatus status;
  final String? triggeredBy;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? escalationLevel;
  final String? escalationNotes;
  final Map<String, dynamic>? metadata;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlertRecord({
    required this.id,
    required this.patientId,
    this.patientName,
    this.deviceId,
    required this.title,
    required this.description,
    this.level = 'warning',
    this.category = 'vital',
    this.riskScore,
    this.status = AlertStatus.active,
    this.triggeredBy,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedBy,
    this.resolvedAt,
    this.escalationLevel,
    this.escalationNotes,
    this.metadata,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  AlertRecord copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? deviceId,
    String? title,
    String? description,
    String? level,
    String? category,
    double? riskScore,
    AlertStatus? status,
    String? triggeredBy,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? escalationLevel,
    String? escalationNotes,
    Map<String, dynamic>? metadata,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      deviceId: deviceId ?? this.deviceId,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      category: category ?? this.category,
      riskScore: riskScore ?? this.riskScore,
      status: status ?? this.status,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      escalationNotes: escalationNotes ?? this.escalationNotes,
      metadata: metadata ?? this.metadata,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AlertRecord.fromJson(Map<String, dynamic> json) {
    return AlertRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String?,
      deviceId: json['deviceId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      level: json['level'] as String? ?? 'warning',
      category: json['category'] as String? ?? 'vital',
      riskScore: (json['riskScore'] as num?)?.toDouble(),
      status: json['status'] != null
          ? AlertStatus.values.firstWhere((e) => e.name == json['status'])
          : AlertStatus.active,
      triggeredBy: json['triggeredBy'] as String?,
      acknowledgedBy: json['acknowledgedBy'] as String?,
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      escalationLevel: json['escalationLevel'] as String?,
      escalationNotes: json['escalationNotes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      assignedTo: json['assignedTo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'deviceId': deviceId,
      'title': title,
      'description': description,
      'level': level,
      'category': category,
      'riskScore': riskScore,
      'status': status.name,
      'triggeredBy': triggeredBy,
      'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'escalationLevel': escalationLevel,
      'escalationNotes': escalationNotes,
      'metadata': metadata,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, title, level, status, createdAt];
}
