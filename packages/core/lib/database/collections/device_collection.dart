import 'package:isar_community/isar.dart';
import 'package:shared/shared.dart';

part 'device_collection.isar_generator.g.part';

@collection
class DeviceCollection {
  Id? isarId;

  @Index(unique: true)
  late String id;

  @Index(unique: true)
  late String serialNumber;

  String? name;
  late String type;
  late String status;

  @Index()
  String? patientId;

  @Index()
  String? hospitalId;

  late double batteryLevel;
  late int signalStrength;
  late String firmwareVersion;
  String? hardwareVersion;
  late DateTime lastHeartbeat;
  DateTime? lastReadingAt;
  DateTime? pairedAt;
  late DateTime createdAt;

  DeviceCollection();

  Device toEntity() => Device(
        id: id,
        serialNumber: serialNumber,
        name: name,
        type: DeviceType.values.firstWhere((t) => t.name == type),
        status: DeviceStatus.values.firstWhere((s) => s.name == status),
        patientId: patientId,
        hospitalId: hospitalId,
        batteryLevel: batteryLevel,
        signalStrength: signalStrength,
        firmwareVersion: firmwareVersion,
        hardwareVersion: hardwareVersion,
        lastHeartbeat: lastHeartbeat,
        lastReadingAt: lastReadingAt,
        pairedAt: pairedAt,
        createdAt: createdAt,
      );

  factory DeviceCollection.fromEntity(Device d) => DeviceCollection()
    ..id = d.id
    ..serialNumber = d.serialNumber
    ..name = d.name
    ..type = d.type.name
    ..status = d.status.name
    ..patientId = d.patientId
    ..hospitalId = d.hospitalId
    ..batteryLevel = d.batteryLevel
    ..signalStrength = d.signalStrength
    ..firmwareVersion = d.firmwareVersion
    ..hardwareVersion = d.hardwareVersion
    ..lastHeartbeat = d.lastHeartbeat
    ..lastReadingAt = d.lastReadingAt
    ..pairedAt = d.pairedAt
    ..createdAt = d.createdAt;

  Map<String, dynamic> toJson() => {
        'isarId': isarId,
        'id': id,
        'serialNumber': serialNumber,
        'name': name,
        'type': type,
        'status': status,
        'patientId': patientId,
        'hospitalId': hospitalId,
        'batteryLevel': batteryLevel,
        'signalStrength': signalStrength,
        'firmwareVersion': firmwareVersion,
        'hardwareVersion': hardwareVersion,
        'lastHeartbeat': lastHeartbeat.toIso8601String(),
        'lastReadingAt': lastReadingAt?.toIso8601String(),
        'pairedAt': pairedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory DeviceCollection.fromJson(Map<String, dynamic> json) =>
      DeviceCollection()
        ..isarId = json['isarId'] as int?
        ..id = json['id'] as String
        ..serialNumber = json['serialNumber'] as String
        ..name = json['name'] as String?
        ..type = json['type'] as String
        ..status = json['status'] as String
        ..patientId = json['patientId'] as String?
        ..hospitalId = json['hospitalId'] as String?
        ..batteryLevel = (json['batteryLevel'] as num).toDouble()
        ..signalStrength = json['signalStrength'] as int
        ..firmwareVersion = json['firmwareVersion'] as String
        ..hardwareVersion = json['hardwareVersion'] as String?
        ..lastHeartbeat = DateTime.parse(json['lastHeartbeat'] as String)
        ..lastReadingAt = json['lastReadingAt'] != null
            ? DateTime.parse(json['lastReadingAt'] as String)
            : null
        ..pairedAt = json['pairedAt'] != null
            ? DateTime.parse(json['pairedAt'] as String)
            : null
        ..createdAt = DateTime.parse(json['createdAt'] as String);
}
