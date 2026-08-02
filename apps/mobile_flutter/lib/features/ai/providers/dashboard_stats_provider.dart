import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_api_providers.dart';

class DashboardStatsState {
  final bool isLoading;
  final DashboardStatsDto? stats;
  final String? error;

  const DashboardStatsState({
    this.isLoading = false,
    this.stats,
    this.error,
  });

  DashboardStatsState copyWith({
    bool? isLoading,
    DashboardStatsDto? stats,
    String? error,
    bool clearError = false,
  }) {
    return DashboardStatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  final AIApi _aiApi;

  DashboardStatsNotifier(this._aiApi) : super(const DashboardStatsState());

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _aiApi.getDashboardStats();
      final result = DashboardStatsDto.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = state.copyWith(isLoading: false, stats: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const DashboardStatsState();
  }
}

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, DashboardStatsState>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  return DashboardStatsNotifier(aiApi);
});
