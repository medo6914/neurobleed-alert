import 'package:isar_community/isar.dart';
import 'package:shared/shared.dart';

part 'sensor_reading_collection.isar_generator.g.part';

@collection
class SensorReadingCollection {
  Id? isarId;

  @Index(unique: true)
  late String id;

  @Index()
  late String deviceId;

  @Index()
  late String patientId;

  late double heartRate;
  late double oxygenSaturation;
  late double systolicBP;
  late double diastolicBP;
  late double temperature;
  late double respiratoryRate;
  late double icp;
  late double cpp;
  double? motionArtifact;
  late int signalQuality;
  double? riskScore;

  @Index()
  late DateTime timestamp;

  late DateTime receivedAt;

  SensorReadingCollection();

  SensorReading toEntity() => SensorReading(
        id: id,
        deviceId: deviceId,
        patientId: patientId,
        heartRate: heartRate,
        oxygenSaturation: oxygenSaturation,
        systolicBP: systolicBP,
        diastolicBP: diastolicBP,
        temperature: temperature,
        respiratoryRate: respiratoryRate,
        icp: icp,
        cpp: cpp,
        motionArtifact: motionArtifact,
        signalQuality: signalQuality,
        riskScore: riskScore,
        timestamp: timestamp,
        receivedAt: receivedAt,
      );

  factory SensorReadingCollection.fromEntity(SensorReading r) =>
      SensorReadingCollection()
        ..id = r.id
        ..deviceId = r.deviceId
        ..patientId = r.patientId
        ..heartRate = r.heartRate
        ..oxygenSaturation = r.oxygenSaturation
        ..systolicBP = r.systolicBP
        ..diastolicBP = r.diastolicBP
        ..temperature = r.temperature
        ..respiratoryRate = r.respiratoryRate
        ..icp = r.icp
        ..cpp = r.cpp
        ..motionArtifact = r.motionArtifact
        ..signalQuality = r.signalQuality
        ..riskScore = r.riskScore
        ..timestamp = r.timestamp
        ..receivedAt = r.receivedAt;

  Map<String, dynamic> toJson() => {
        'isarId': isarId,
        'id': id,
        'deviceId': deviceId,
        'patientId': patientId,
        'heartRate': heartRate,
        'oxygenSaturation': oxygenSaturation,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'temperature': temperature,
        'respiratoryRate': respiratoryRate,
        'icp': icp,
        'cpp': cpp,
        'motionArtifact': motionArtifact,
        'signalQuality': signalQuality,
        'riskScore': riskScore,
        'timestamp': timestamp.toIso8601String(),
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory SensorReadingCollection.fromJson(Map<String, dynamic> json) =>
      SensorReadingCollection()
        ..isarId = json['isarId'] as int?
        ..id = json['id'] as String
        ..deviceId = json['deviceId'] as String
        ..patientId = json['patientId'] as String
        ..heartRate = (json['heartRate'] as num).toDouble()
        ..oxygenSaturation = (json['oxygenSaturation'] as num).toDouble()
        ..systolicBP = (json['systolicBP'] as num).toDouble()
        ..diastolicBP = (json['diastolicBP'] as num).toDouble()
        ..temperature = (json['temperature'] as num).toDouble()
        ..respiratoryRate = (json['respiratoryRate'] as num).toDouble()
        ..icp = (json['icp'] as num).toDouble()
        ..cpp = (json['cpp'] as num).toDouble()
        ..motionArtifact = (json['motionArtifact'] as num?)?.toDouble()
        ..signalQuality = json['signalQuality'] as int? ?? 100
        ..riskScore = (json['riskScore'] as num?)?.toDouble()
        ..timestamp = DateTime.parse(json['timestamp'] as String)
        ..receivedAt = DateTime.parse(json['receivedAt'] as String);
}
