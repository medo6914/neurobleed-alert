import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../network/dtos/device/device_dtos.dart';
import '../../repositories/device_repository.dart';
import '../../security/audit_logger.dart';

class UpdateDevice {
  final DeviceRepository _repository;
  final AuditLogger? _auditLogger;

  UpdateDevice(this._repository, [this._auditLogger]);

  Future<Either<Failure, Device>> call(
    String id,
    DeviceUpdateRequest updates, {
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (id.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {'id': ['Device ID is required']},
      ));
    }

    final result = await _repository.updateDevice(id, updates);

    result.fold(
      (failure) {},
      (updated) {
        _auditLogger?.logUpdate(
          patientId: updated.id,
          resourceType: 'device',
          resourceId: updated.id,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
