import 'package:dartz/dartz.dart';
import '../../error/failure.dart';
import '../../network/dtos/device/device_diagnostics.dart';
import '../../repositories/device_repository.dart';

class GetDeviceDiagnostics {
  final DeviceRepository _repository;

  GetDeviceDiagnostics(this._repository);

  Future<Either<Failure, DeviceDiagnostics>> call(String id) async {
    if (id.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {'id': ['Device ID is required']},
      ));
    }
    return _repository.getDiagnostics(id);
  }
}
