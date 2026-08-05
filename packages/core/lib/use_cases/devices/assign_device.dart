import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../network/dtos/device/device_dtos.dart';
import '../../repositories/device_repository.dart';
import '../../security/audit_logger.dart';

class AssignDevice {
  final DeviceRepository _repository;
  final AuditLogger? _auditLogger;

  AssignDevice(this._repository, [this._auditLogger]);

  Future<Either<Failure, Device>> call({
    required String deviceId,
    String? patientId,
    String? hospitalId,
    String? department,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (deviceId.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'deviceId': ['Device ID is required']
        },
      ));
    }

    final request = DeviceAssignRequest(
      patientId: patientId,
      hospitalId: hospitalId,
      department: department,
    );

    final result = await _repository.assignDevice(deviceId, request);

    result.fold(
      (failure) {},
      (assigned) {
        _auditLogger?.logUpdate(
          patientId: assigned.id,
          resourceType: 'device',
          resourceId: assigned.id,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
