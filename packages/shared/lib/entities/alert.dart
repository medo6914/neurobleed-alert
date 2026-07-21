import 'package:equatable/equatable.dart';

enum AlertLevel {
  info,
  warning,
  critical,
}

enum AlertCategory {
  vitalSigns,
  riskScore,
  device,
  system,
  emergency,
}

class Alert extends Equatable {
  final String id;
  final String patientId;
  final String? patientName;
  final String title;
  final String description;
  final AlertLevel level;
  final AlertCategory category;
  final double? riskScore;
  final String? triggeredBy;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final bool isResolved;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const Alert({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.title,
    required this.description,
    this.level = AlertLevel.info,
    this.category = AlertCategory.vitalSigns,
    this.riskScore,
    this.triggeredBy,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.isResolved = false,
    this.resolvedAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        title,
        level,
        createdAt,
      ];
}
