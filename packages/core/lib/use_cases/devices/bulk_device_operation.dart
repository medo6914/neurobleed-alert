import 'package:dartz/dartz.dart';
import '../../error/failure.dart';
import '../../network/dtos/device/device_dtos.dart';
import '../../repositories/device_repository.dart';
import '../../security/audit_logger.dart';

class BulkDeviceOperation {
  final DeviceRepository _repository;
  final AuditLogger? _auditLogger;

  BulkDeviceOperation(this._repository, [this._auditLogger]);

  Future<Either<Failure, List<Map<String, dynamic>>>> call(
    List<String> deviceIds,
    String operation, {
    String? firmwareVersion,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (deviceIds.isEmpty) {
      return Left(ValidationFailure(
        message: 'At least one device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'deviceIds': ['At least one device ID is required']
        },
      ));
    }

    if (operation.isEmpty) {
      return Left(ValidationFailure(
        message: 'Operation is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'operation': ['Operation is required']
        },
      ));
    }

    final request = BulkOperationRequest(
      deviceIds: deviceIds,
      operation: operation,
      firmwareVersion: firmwareVersion,
    );

    final result = await _repository.bulkOperation(request);

    result.fold(
      (failure) {},
      (_) {
        for (final deviceId in deviceIds) {
          _auditLogger?.logUpdate(
            patientId: deviceId,
            resourceType: 'device',
            resourceId: deviceId,
            userId: userId,
            userName: userName,
            userRole: userRole,
          );
        }
      },
    );

    return result;
  }
}
