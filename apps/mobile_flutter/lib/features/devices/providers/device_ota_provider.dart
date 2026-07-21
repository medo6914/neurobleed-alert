import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'device_repository_providers.dart';

class DeviceOtaState {
  final bool isUpdating;
  final double progress;
  final String? error;
  final dynamic result;

  const DeviceOtaState({
    this.isUpdating = false,
    this.progress = 0,
    this.error,
    this.result,
  });

  DeviceOtaState copyWith({
    bool? isUpdating,
    double? progress,
    String? error,
    dynamic result,
    bool clearError = false,
  }) {
    return DeviceOtaState(
      isUpdating: isUpdating ?? this.isUpdating,
      progress: progress ?? this.progress,
      error: clearError ? null : error ?? this.error,
      result: result ?? this.result,
    );
  }
}

class DeviceOtaNotifier extends StateNotifier<DeviceOtaState> {
  final DeviceRepository _repository;

  DeviceOtaNotifier(this._repository) : super(const DeviceOtaState());

  Future<Either<Failure, dynamic>> triggerOta(String deviceId, String firmwareVersion) async {
    state = state.copyWith(isUpdating: true, progress: 0, clearError: true);

    final request = BulkOperationRequest(
      deviceIds: [deviceId],
      operation: 'ota_update',
      firmwareVersion: firmwareVersion,
    );

    final result = await _repository.bulkOperation(request);

    result.fold(
      (failure) {
        state = state.copyWith(isUpdating: false, error: failure.message);
      },
      (response) {
        state = state.copyWith(isUpdating: false, progress: 100, result: response);
      },
    );

    return result;
  }

  void setProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  void reset() {
    state = const DeviceOtaState();
  }
}

final deviceOtaProvider = StateNotifierProvider<DeviceOtaNotifier, DeviceOtaState>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return DeviceOtaNotifier(repository);
});
