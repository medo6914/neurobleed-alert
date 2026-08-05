import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'device_repository_providers.dart';

class DeviceFormState {
  final bool isSubmitting;
  final String? error;
  final Map<String, List<String>> validationErrors;

  const DeviceFormState({
    this.isSubmitting = false,
    this.error,
    this.validationErrors = const {},
  });

  DeviceFormState copyWith({
    bool? isSubmitting,
    String? error,
    Map<String, List<String>>? validationErrors,
    bool clearError = false,
  }) {
    return DeviceFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class RegisterDeviceNotifier extends StateNotifier<DeviceFormState> {
  final DeviceRepository _repository;

  RegisterDeviceNotifier(this._repository) : super(const DeviceFormState());

  Future<Either<Failure, Device>> submitRegister(
      DeviceCreateRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await _repository.registerDevice(request);

    result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: failure.message,
          validationErrors: failure is ValidationFailure ? failure.errors : {},
        );
      },
      (_) {
        state = const DeviceFormState();
      },
    );

    return result;
  }
}

final registerDeviceProvider =
    StateNotifierProvider<RegisterDeviceNotifier, DeviceFormState>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return RegisterDeviceNotifier(repository);
});

class UpdateDeviceNotifier extends StateNotifier<DeviceFormState> {
  final DeviceRepository _repository;

  UpdateDeviceNotifier(this._repository) : super(const DeviceFormState());

  Future<Either<Failure, Device>> submitUpdate(
      String id, DeviceUpdateRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    final result = await _repository.updateDevice(id, request);

    result.fold(
      (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: failure.message,
          validationErrors: failure is ValidationFailure ? failure.errors : {},
        );
      },
      (_) {
        state = const DeviceFormState();
      },
    );

    return result;
  }
}

final updateDeviceProvider =
    StateNotifierProvider<UpdateDeviceNotifier, DeviceFormState>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return UpdateDeviceNotifier(repository);
});
