import 'package:equatable/equatable.dart';

enum TimelineEventType {
  admission,
  discharge,
  transfer,
  surgery,
  procedure,
  diagnosis,
  medicationChange,
  labResult,
  imagingResult,
  consultation,
  note,
  alertTriggered,
  riskAssessment,
  vitalsAbnormal,
  statusChange,
  other,
}

class MedicalTimelineEntry extends Equatable {
  final String id;
  final String patientId;
  final String? encounterId;
  final TimelineEventType eventType;
  final String title;
  final String description;
  final Map<String, dynamic>? metadata;
  final String? createdBy;
  final String? createdByName;
  final DateTime timestamp;
  final DateTime createdAt;

  const MedicalTimelineEntry({
    required this.id,
    required this.patientId,
    this.encounterId,
    required this.eventType,
    required this.title,
    required this.description,
    this.metadata,
    this.createdBy,
    this.createdByName,
    required this.timestamp,
    required this.createdAt,
  });

  MedicalTimelineEntry copyWith({
    String? id,
    String? patientId,
    String? encounterId,
    TimelineEventType? eventType,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
    String? createdBy,
    String? createdByName,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return MedicalTimelineEntry(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MedicalTimelineEntry.fromJson(Map<String, dynamic> json) {
    return MedicalTimelineEntry(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      encounterId: json['encounterId'] as String?,
      eventType: TimelineEventType.values.firstWhere((e) => e.name == json['eventType']),
      title: json['title'] as String,
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdBy: json['createdBy'] as String?,
      createdByName: json['createdByName'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'eventType': eventType.name,
      'title': title,
      'description': description,
      'metadata': metadata,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, eventType, title, timestamp];
}
