import 'package:shared/shared.dart';
import 'device_dto.dart';

class DeviceMapper {
  static Device toEntity(DeviceDto dto) {
    return Device(
      id: dto.id,
      serialNumber: dto.serialNumber,
      name: dto.deviceName,
      type: _parseDeviceType(dto.deviceType),
      status: _parseDeviceStatus(dto.status),
      patientId: dto.patientId,
      hospitalId: dto.hospitalId,
      batteryLevel: dto.batteryLevel ?? 0,
      signalStrength: dto.signalStrength ?? 0,
      firmwareVersion: dto.firmwareVersion ?? '1.0.0',
      hardwareVersion: dto.hardwareVersion,
      lastHeartbeat: dto.lastHeartbeat ?? DateTime.now(),
      lastReadingAt: dto.lastSeen,
      pairedAt: null,
      createdAt: dto.createdAt,
    );
  }

  static List<Device> toEntityList(List<DeviceDto> dtos) =>
      dtos.map(toEntity).toList();

  static DeviceType _parseDeviceType(String? type) {
    if (type == null) return DeviceType.headband;
    return DeviceType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => DeviceType.headband,
    );
  }

  static DeviceStatus _parseDeviceStatus(String? status) {
    if (status == null) return DeviceStatus.offline;
    return DeviceStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => DeviceStatus.offline,
    );
  }
}
