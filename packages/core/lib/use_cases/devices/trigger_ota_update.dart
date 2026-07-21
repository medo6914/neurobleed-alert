import 'package:dartz/dartz.dart';
import '../../error/failure.dart';
import '../../network/dtos/device/device_dtos.dart';
import '../../repositories/device_repository.dart';
import '../../validators/device_validator.dart';
import '../../security/audit_logger.dart';

class TriggerOtaUpdate {
  final DeviceRepository _repository;
  final AuditLogger? _auditLogger;

  TriggerOtaUpdate(this._repository, [this._auditLogger]);

  Future<Either<Failure, dynamic>> call(
    String deviceId,
    String firmwareVersion, {
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (deviceId.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {'deviceId': ['Device ID is required']},
      ));
    }

    final fwResult =
        DeviceValidator.validateFirmwareVersion(firmwareVersion);
    if (fwResult.isLeft()) {
      return fwResult as Left<Failure, dynamic>;
    }

    final result = await _repository.bulkOperation(BulkOperationRequest(
      deviceIds: [deviceId],
      operation: 'ota_update',
      firmwareVersion: firmwareVersion,
    ));

    result.fold(
      (failure) {},
      (_) {
        _auditLogger?.logUpdate(
          patientId: deviceId,
          resourceType: 'device',
          resourceId: deviceId,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
