import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

class HistoryState {
  final List<dynamic> activityFeed;
  final List<dynamic> alerts;
  final List<dynamic> reports;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.activityFeed = const [],
    this.alerts = const [],
    this.reports = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<dynamic>? activityFeed,
    List<dynamic>? alerts,
    List<dynamic>? reports,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      activityFeed: activityFeed ?? this.activityFeed,
      alerts: alerts ?? this.alerts,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final ApiClient _api;

  HistoryNotifier(this._api) : super(const HistoryState());

  Future<void> loadAll({String? patientId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final futures = <Future<dynamic>>[];

      futures.add(_api.get('/v1/analytics/activity-feed', queryParameters: {
        'limit': 100,
      }));

      futures.add(_api.get('/v1/alerts', queryParameters: {
        'per_page': 100,
        'sort_by': 'created_at',
        'sort_order': 'desc',
        if (patientId != null) 'patient_id': patientId,
      }));

      futures.add(_api.get('/v1/reports', queryParameters: {
        'per_page': 50,
        'sort_by': 'created_at',
        'sort_order': 'desc',
        if (patientId != null) 'patient_id': patientId,
      }));

      final results = await Future.wait(futures);

      final feedData = results[0] as dynamic;
      final alertsData = results[1] as dynamic;
      final reportsData = results[2] as dynamic;

      final feedList = feedData is List
          ? List<dynamic>.from(feedData)
          : feedData is Map && feedData['items'] != null
              ? List<dynamic>.from(feedData['items'])
              : <dynamic>[];

      final alertsList = alertsData is Map && alertsData['items'] != null
          ? List<dynamic>.from(alertsData['items'])
          : alertsData is List
              ? List<dynamic>.from(alertsData)
              : <dynamic>[];

      final reportsList = reportsData is Map && reportsData['items'] != null
          ? List<dynamic>.from(reportsData['items'])
          : reportsData is List
              ? List<dynamic>.from(reportsData)
              : <dynamic>[];

      state = state.copyWith(
        activityFeed: feedList,
        alerts: alertsList,
        reports: reportsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HistoryNotifier(apiClient);
});
