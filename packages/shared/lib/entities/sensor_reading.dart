import 'package:equatable/equatable.dart';

class SensorReading extends Equatable {
  final String id;
  final String deviceId;
  final String patientId;
  final double heartRate;
  final double oxygenSaturation;
  final double systolicBP;
  final double diastolicBP;
  final double temperature;
  final double respiratoryRate;
  final double icp;
  final double cpp;
  final double? motionArtifact;
  final int signalQuality;
  final double? riskScore;
  final DateTime timestamp;
  final DateTime receivedAt;

  const SensorReading({
    required this.id,
    required this.deviceId,
    required this.patientId,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.systolicBP,
    required this.diastolicBP,
    required this.temperature,
    required this.respiratoryRate,
    required this.icp,
    required this.cpp,
    this.motionArtifact,
    this.signalQuality = 100,
    this.riskScore,
    required this.timestamp,
    required this.receivedAt,
  });

  @override
  List<Object?> get props => [
        id,
        deviceId,
        patientId,
        heartRate,
        oxygenSaturation,
        systolicBP,
        diastolicBP,
        temperature,
        respiratoryRate,
        icp,
        cpp,
        timestamp,
      ];
}
