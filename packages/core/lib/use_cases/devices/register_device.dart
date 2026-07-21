import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../network/dtos/device/device_dtos.dart';
import '../../repositories/device_repository.dart';
import '../../security/audit_logger.dart';
import '../../validators/device_validator.dart';

class RegisterDevice {
  final DeviceRepository _repository;
  final AuditLogger? _auditLogger;

  RegisterDevice(this._repository, [this._auditLogger]);

  Future<Either<Failure, Device>> call({
    required String serialNumber,
    String? deviceName,
    DeviceType? deviceType,
    String? macAddress,
    String? firmwareVersion,
    String? hardwareVersion,
    String? hospitalId,
    String? department,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    final serialResult = DeviceValidator.validateSerialNumber(serialNumber);
    if (serialResult.isLeft()) {
      return serialResult as Left<Failure, Device>;
    }

    final nameResult = DeviceValidator.validateDeviceName(deviceName);
    if (nameResult.isLeft()) {
      return nameResult as Left<Failure, Device>;
    }

    if (macAddress != null) {
      final macResult = DeviceValidator.validateMacAddress(macAddress);
      if (macResult.isLeft()) {
        return macResult as Left<Failure, Device>;
      }
    }

    if (firmwareVersion != null) {
      final fwResult =
          DeviceValidator.validateFirmwareVersion(firmwareVersion);
      if (fwResult.isLeft()) {
        return fwResult as Left<Failure, Device>;
      }
    }

    final request = DeviceCreateRequest(
      serialNumber: serialNumber,
      deviceName: deviceName,
      deviceType: deviceType?.name,
      macAddress: macAddress,
      firmwareVersion: firmwareVersion,
      hardwareVersion: hardwareVersion,
      hospitalId: hospitalId,
      department: department,
    );

    final result = await _repository.registerDevice(request);

    result.fold(
      (failure) {},
      (created) {
        _auditLogger?.logCreate(
          patientId: created.id,
          resourceType: 'device',
          resourceId: created.id,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
