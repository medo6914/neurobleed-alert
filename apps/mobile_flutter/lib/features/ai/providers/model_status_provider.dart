import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_api_providers.dart';

class ModelStatusState {
  final bool isLoading;
  final ModelStatusDto? status;
  final String? error;

  const ModelStatusState({
    this.isLoading = false,
    this.status,
    this.error,
  });

  ModelStatusState copyWith({
    bool? isLoading,
    ModelStatusDto? status,
    String? error,
    bool clearError = false,
  }) {
    return ModelStatusState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ModelStatusNotifier extends StateNotifier<ModelStatusState> {
  final AIApi _aiApi;

  ModelStatusNotifier(this._aiApi) : super(const ModelStatusState());

  Future<void> fetchStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _aiApi.getModelStatus();
      final result = ModelStatusDto.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, status: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> trainModel(Map<String, dynamic> config) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _aiApi.trainModel(config);
      final result = ModelStatusDto.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, status: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const ModelStatusState();
  }
}

final modelStatusProvider =
    StateNotifierProvider<ModelStatusNotifier, ModelStatusState>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  return ModelStatusNotifier(aiApi);
});
