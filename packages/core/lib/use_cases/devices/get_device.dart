import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/device_repository.dart';

class GetDevice {
  final DeviceRepository _repository;

  GetDevice(this._repository);

  Future<Either<Failure, Device>> call(String id) async {
    if (id.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'id': ['Device ID is required']
        },
      ));
    }
    return _repository.getDevice(id);
  }
}
