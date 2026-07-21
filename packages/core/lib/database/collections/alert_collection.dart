import 'package:isar_community/isar.dart';
import 'package:shared/shared.dart';

part 'alert_collection.isar_generator.g.part';

@collection
class AlertCollection {
  Id? isarId;

  @Index(unique: true)
  late String id;

  @Index()
  late String patientId;

  String? patientName;
  late String title;
  late String description;
  late String level;
  late String category;
  double? riskScore;
  String? triggeredBy;
  late bool isAcknowledged;
  String? acknowledgedBy;
  DateTime? acknowledgedAt;
  late bool isResolved;
  DateTime? resolvedAt;

  @Index()
  late DateTime createdAt;

  AlertCollection();

  Alert toEntity() => Alert(
        id: id,
        patientId: patientId,
        patientName: patientName,
        title: title,
        description: description,
        level: AlertLevel.values.firstWhere((l) => l.name == level),
        category: AlertCategory.values.firstWhere((c) => c.name == category),
        riskScore: riskScore,
        triggeredBy: triggeredBy,
        isAcknowledged: isAcknowledged,
        acknowledgedBy: acknowledgedBy,
        acknowledgedAt: acknowledgedAt,
        isResolved: isResolved,
        resolvedAt: resolvedAt,
        createdAt: createdAt,
      );

  factory AlertCollection.fromEntity(Alert a) => AlertCollection()
    ..id = a.id
    ..patientId = a.patientId
    ..patientName = a.patientName
    ..title = a.title
    ..description = a.description
    ..level = a.level.name
    ..category = a.category.name
    ..riskScore = a.riskScore
    ..triggeredBy = a.triggeredBy
    ..isAcknowledged = a.isAcknowledged
    ..acknowledgedBy = a.acknowledgedBy
    ..acknowledgedAt = a.acknowledgedAt
    ..isResolved = a.isResolved
    ..resolvedAt = a.resolvedAt
    ..createdAt = a.createdAt;

  Map<String, dynamic> toJson() => {
        'isarId': isarId,
        'id': id,
        'patientId': patientId,
        'patientName': patientName,
        'title': title,
        'description': description,
        'level': level,
        'category': category,
        'riskScore': riskScore,
        'triggeredBy': triggeredBy,
        'isAcknowledged': isAcknowledged,
        'acknowledgedBy': acknowledgedBy,
        'acknowledgedAt': acknowledgedAt?.toIso8601String(),
        'isResolved': isResolved,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory AlertCollection.fromJson(Map<String, dynamic> json) =>
      AlertCollection()
        ..isarId = json['isarId'] as int?
        ..id = json['id'] as String
        ..patientId = json['patientId'] as String
        ..patientName = json['patientName'] as String?
        ..title = json['title'] as String
        ..description = json['description'] as String
        ..level = json['level'] as String
        ..category = json['category'] as String
        ..riskScore = (json['riskScore'] as num?)?.toDouble()
        ..triggeredBy = json['triggeredBy'] as String?
        ..isAcknowledged = json['isAcknowledged'] as bool? ?? false
        ..acknowledgedBy = json['acknowledgedBy'] as String?
        ..acknowledgedAt = json['acknowledgedAt'] != null
            ? DateTime.parse(json['acknowledgedAt'] as String)
            : null
        ..isResolved = json['isResolved'] as bool? ?? false
        ..resolvedAt = json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null
        ..createdAt = DateTime.parse(json['createdAt'] as String);
}
