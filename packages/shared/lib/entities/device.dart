import 'package:equatable/equatable.dart';

enum DeviceType {
  headband,
  wearable,
  bedside,
}

enum DeviceStatus {
  online,
  offline,
  pairing,
  error,
  lowBattery,
  maintenance,
}

class Device extends Equatable {
  final String id;
  final String serialNumber;
  final String? name;
  final DeviceType type;
  final DeviceStatus status;
  final String? patientId;
  final String? hospitalId;
  final double batteryLevel;
  final int signalStrength;
  final String firmwareVersion;
  final String? hardwareVersion;
  final DateTime lastHeartbeat;
  final DateTime? lastReadingAt;
  final DateTime? pairedAt;
  final DateTime createdAt;

  const Device({
    required this.id,
    required this.serialNumber,
    this.name,
    required this.type,
    this.status = DeviceStatus.offline,
    this.patientId,
    this.hospitalId,
    this.batteryLevel = 100,
    this.signalStrength = 0,
    this.firmwareVersion = '1.0.0',
    this.hardwareVersion,
    required this.lastHeartbeat,
    this.lastReadingAt,
    this.pairedAt,
    required this.createdAt,
  });

  bool get needsCharge => batteryLevel < 20;

  bool get isConnected => status == DeviceStatus.online;

  Device copyWith({DeviceStatus? status, double? batteryLevel}) {
    return Device(
      id: id,
      serialNumber: serialNumber,
      name: name,
      type: type,
      status: status ?? this.status,
      patientId: patientId,
      hospitalId: hospitalId,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrength: signalStrength,
      firmwareVersion: firmwareVersion,
      hardwareVersion: hardwareVersion,
      lastHeartbeat: lastHeartbeat,
      lastReadingAt: lastReadingAt,
      pairedAt: pairedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, serialNumber];
}
