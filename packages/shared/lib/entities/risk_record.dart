import 'package:equatable/equatable.dart';

class RiskRecord extends Equatable {
  final String id;
  final String patientId;
  final String? encounterId;
  final String riskType;
  final double score;
  final String level;
  final Map<String, dynamic>? factors;
  final String? modelVersion;
  final String? assessedBy;
  final String? notes;
  final DateTime timestamp;
  final DateTime createdAt;

  const RiskRecord({
    required this.id,
    required this.patientId,
    this.encounterId,
    required this.riskType,
    required this.score,
    this.level = 'low',
    this.factors,
    this.modelVersion,
    this.assessedBy,
    this.notes,
    required this.timestamp,
    required this.createdAt,
  });

  RiskRecord copyWith({
    String? id,
    String? patientId,
    String? encounterId,
    String? riskType,
    double? score,
    String? level,
    Map<String, dynamic>? factors,
    String? modelVersion,
    String? assessedBy,
    String? notes,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return RiskRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      encounterId: encounterId ?? this.encounterId,
      riskType: riskType ?? this.riskType,
      score: score ?? this.score,
      level: level ?? this.level,
      factors: factors ?? this.factors,
      modelVersion: modelVersion ?? this.modelVersion,
      assessedBy: assessedBy ?? this.assessedBy,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory RiskRecord.fromJson(Map<String, dynamic> json) {
    return RiskRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      encounterId: json['encounterId'] as String?,
      riskType: json['riskType'] as String,
      score: (json['score'] as num).toDouble(),
      level: json['level'] as String? ?? 'low',
      factors: json['factors'] as Map<String, dynamic>?,
      modelVersion: json['modelVersion'] as String?,
      assessedBy: json['assessedBy'] as String?,
      notes: json['notes'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'encounterId': encounterId,
      'riskType': riskType,
      'score': score,
      'level': level,
      'factors': factors,
      'modelVersion': modelVersion,
      'assessedBy': assessedBy,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, riskType, score, timestamp];
}
