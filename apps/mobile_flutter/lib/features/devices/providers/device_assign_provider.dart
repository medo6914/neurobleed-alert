import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'device_repository_providers.dart';

class DeviceAssignState {
  final bool isSubmitting;
  final String? error;

  const DeviceAssignState({
    this.isSubmitting = false,
    this.error,
  });

  DeviceAssignState copyWith({
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return DeviceAssignState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class DeviceAssignNotifier extends StateNotifier<DeviceAssignState> {
  final DeviceRepository _repository;

  DeviceAssignNotifier(this._repository) : super(const DeviceAssignState());

  Future<Either<Failure, Device>> assignDevice({
    required String deviceId,
    String? patientId,
    String? hospitalId,
    String? department,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final request = DeviceAssignRequest(
      patientId: patientId,
      hospitalId: hospitalId,
      department: department,
    );

    final result = await _repository.assignDevice(deviceId, request);

    result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, error: failure.message);
      },
      (_) {
        state = const DeviceAssignState();
      },
    );

    return result;
  }

  Future<Either<Failure, Device>> unassignDevice(String deviceId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await _repository.unassignDevice(deviceId);

    result.fold(
      (failure) {
        state = state.copyWith(isSubmitting: false, error: failure.message);
      },
      (_) {
        state = const DeviceAssignState();
      },
    );

    return result;
  }
}

final deviceAssignProvider = StateNotifierProvider<DeviceAssignNotifier, DeviceAssignState>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return DeviceAssignNotifier(repository);
});
