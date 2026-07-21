import 'package:dartz/dartz.dart';
import '../../error/failure.dart';
import '../../repositories/device_repository.dart';

class GetDeviceHistory {
  final DeviceRepository _repository;

  GetDeviceHistory(this._repository);

  Future<Either<Failure, List<dynamic>>> call(
    String deviceId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (deviceId.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {'deviceId': ['Device ID is required']},
      ));
    }
    return _repository.getHistory(deviceId, page: page, limit: limit);
  }
}
