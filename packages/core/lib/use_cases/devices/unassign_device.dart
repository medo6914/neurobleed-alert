import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/device_repository.dart';
import '../../security/audit_logger.dart';

class UnassignDevice {
  final DeviceRepository _repository;
  final AuditLogger? _auditLogger;

  UnassignDevice(this._repository, [this._auditLogger]);

  Future<Either<Failure, Device>> call(
    String id, {
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

    final result = await _repository.unassignDevice(id);

    result.fold(
      (failure) {},
      (unassigned) {
        _auditLogger?.logUpdate(
          patientId: unassigned.id,
          resourceType: 'device',
          resourceId: unassigned.id,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
