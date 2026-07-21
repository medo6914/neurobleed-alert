import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../network/dtos/device/device_dtos.dart';
import '../../repositories/device_repository.dart';

class UpdateDeviceStatus {
  final DeviceRepository _repository;

  UpdateDeviceStatus(this._repository);

  Future<Either<Failure, Device>> call(
    String id,
    DeviceStatus status, {
    double? batteryLevel,
    int? signalStrength,
    double? temperature,
    bool? chargingStatus,
    int? lteSignal,
    String? simStatus,
    String? bleStatus,
  }) async {
    if (id.isEmpty) {
      return Left(ValidationFailure(
        message: 'Device ID is required',
        code: 'VALIDATION_ERROR',
        errors: {'id': ['Device ID is required']},
      ));
    }

    final statusUpdate = DeviceStatusUpdate(
      status: status.name,
      batteryLevel: batteryLevel,
      signalStrength: signalStrength,
      temperature: temperature,
      chargingStatus: chargingStatus,
      lteSignal: lteSignal,
      simStatus: simStatus,
      bleStatus: bleStatus,
    );

    return _repository.updateStatus(id, statusUpdate);
  }
}
