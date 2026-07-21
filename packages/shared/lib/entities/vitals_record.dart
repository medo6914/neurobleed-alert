import 'package:equatable/equatable.dart';

class VitalsRecord extends Equatable {
  final String id;
  final String patientId;
  final String? deviceId;
  final String? encounterId;
  final double? heartRate;
  final double? oxygenSaturation;
  final double? systolicBP;
  final double? diastolicBP;
  final double? temperature;
  final double? respiratoryRate;
  final double? icp;
  final double? cpp;
  final double? glucose;
  final double? painLevel;
  final double? weight;
  final double? height;
  final double? bmi;
  final String? bloodPressurePosition;
  final bool motionArtifact;
  final int? signalQuality;
  final double? riskScore;
  final String? notes;
  final String? recordedBy;
  final String? recordedByName;
  final DateTime timestamp;
  final DateTime createdAt;

  const VitalsRecord({
    required this.id,
    required this.patientId,
    this.deviceId,
    this.encounterId,
    this.heartRate,
    this.oxygenSaturation,
    this.systolicBP,
    this.diastolicBP,
    this.temperature,
    this.respiratoryRate,
    this.icp,
    this.cpp,
    this.glucose,
    this.painLevel,
    this.weight,
    this.height,
    this.bmi,
    this.bloodPressurePosition,
    this.motionArtifact = false,
    this.signalQuality,
    this.riskScore,
    this.notes,
    this.recordedBy,
    this.recordedByName,
    required this.timestamp,
    required this.createdAt,
  });

  VitalsRecord copyWith({
    String? id,
    String? patientId,
    String? deviceId,
    String? encounterId,
    double? heartRate,
    double? oxygenSaturation,
    double? systolicBP,
    double? diastolicBP,
    double? temperature,
    double? respiratoryRate,
    double? icp,
    double? cpp,
    double? glucose,
    double? painLevel,
    double? weight,
    double? height,
    double? bmi,
    String? bloodPressurePosition,
    bool? motionArtifact,
    int? signalQuality,
    double? riskScore,
    String? notes,
    String? recordedBy,
    String? recordedByName,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return VitalsRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      deviceId: deviceId ?? this.deviceId,
      encounterId: encounterId ?? this.encounterId,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      temperature: temperature ?? this.temperature,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      icp: icp ?? this.icp,
      cpp: cpp ?? this.cpp,
      glucose: glucose ?? this.glucose,
      painLevel: painLevel ?? this.painLevel,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      bloodPressurePosition: bloodPressurePosition ?? this.bloodPressurePosition,
      motionArtifact: motionArtifact ?? this.motionArtifact,
      signalQuality: signalQuality ?? this.signalQuality,
      riskScore: riskScore ?? this.riskScore,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedByName: recordedByName ?? this.recordedByName,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory VitalsRecord.fromJson(Map<String, dynamic> json) {
    return VitalsRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      deviceId: json['deviceId'] as String?,
      encounterId: json['encounterId'] as String?,
      heartRate: (json['heartRate'] as num?)?.toDouble(),
      oxygenSaturation: (json['oxygenSaturation'] as num?)?.toDouble(),
      systolicBP: (json['systolicBP'] as num?)?.toDouble(),
      diastolicBP: (json['diastolicBP'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      respiratoryRate: (json['respiratoryRate'] as num?)?.toDouble(),
      icp: (json['icp'] as num?)?.toDouble(),
      cpp: (json['cpp'] as num?)?.toDouble(),
      glucose: (json['glucose'] as num?)?.toDouble(),
      painLevel: (json['painLevel'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bloodPressurePosition: json['bloodPressurePosition'] as String?,
      motionArtifact: json['motionArtifact'] as bool? ?? false,
      signalQuality: json['signalQuality'] as int?,
      riskScore: (json['riskScore'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      recordedBy: json['recordedBy'] as String?,
      recordedByName: json['recordedByName'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'deviceId': deviceId,
      'encounterId': encounterId,
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'temperature': temperature,
      'respiratoryRate': respiratoryRate,
      'icp': icp,
      'cpp': cpp,
      'glucose': glucose,
      'painLevel': painLevel,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'bloodPressurePosition': bloodPressurePosition,
      'motionArtifact': motionArtifact,
      'signalQuality': signalQuality,
      'riskScore': riskScore,
      'notes': notes,
      'recordedBy': recordedBy,
      'recordedByName': recordedByName,
      'timestamp': timestamp.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, timestamp];
}
