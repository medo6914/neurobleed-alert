import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/device_repository.dart';

class ListDevices {
  final DeviceRepository _repository;

  ListDevices(this._repository);

  Future<Either<Failure, List<Device>>> call({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? status,
    String? deviceType,
    String? hospitalId,
    String? patientId,
    String? search,
  }) async {
    return _repository.listDevices(
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      status: status,
      deviceType: deviceType,
      hospitalId: hospitalId,
      patientId: patientId,
      search: search,
    );
  }
}
