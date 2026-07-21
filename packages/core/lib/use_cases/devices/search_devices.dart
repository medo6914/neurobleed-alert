import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/device_repository.dart';

class SearchDevices {
  final DeviceRepository _repository;

  SearchDevices(this._repository);

  Future<Either<Failure, List<Device>>> call(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    if (query.isEmpty) {
      return Left(ValidationFailure(
        message: 'Search query is required',
        code: 'VALIDATION_ERROR',
        errors: {'query': ['Search query is required']},
      ));
    }
    return _repository.searchDevices(query, page: page, limit: limit);
  }
}
