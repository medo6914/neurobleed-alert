import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

class ReportsState {
  final Map<String, dynamic>? overview;
  final List<dynamic> alerts;
  final List<dynamic> readings;
  final List<dynamic> clinicalReports;
  final bool isLoading;
  final String? error;

  const ReportsState({
    this.overview,
    this.alerts = const [],
    this.readings = const [],
    this.clinicalReports = const [],
    this.isLoading = false,
    this.error,
  });

  ReportsState copyWith({
    Map<String, dynamic>? overview,
    List<dynamic>? alerts,
    List<dynamic>? readings,
    List<dynamic>? clinicalReports,
    bool? isLoading,
    String? error,
  }) {
    return ReportsState(
      overview: overview ?? this.overview,
      alerts: alerts ?? this.alerts,
      readings: readings ?? this.readings,
      clinicalReports: clinicalReports ?? this.clinicalReports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ApiClient _api;

  ReportsNotifier(this._api) : super(const ReportsState());

  Future<void> loadAll({String? patientId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final futures = <Future<dynamic>>[];

      futures.add(_api.get('/v1/analytics/overview'));

      futures.add(_api.get('/v1/alerts', queryParameters: {
        'per_page': 50,
        'sort_by': 'created_at',
        'sort_order': 'desc',
        if (patientId != null) 'patient_id': patientId,
      }));

      futures.add(_api.get('/v1/readings', queryParameters: {
        'limit': 100,
        'hours': 24,
        if (patientId != null) 'patient_id': patientId,
      }));

      futures.add(_api.get('/v1/reports', queryParameters: {
        'per_page': 20,
        'sort_by': 'created_at',
        'sort_order': 'desc',
        if (patientId != null) 'patient_id': patientId,
      }));

      final results = await Future.wait(futures);

      final overviewData = results[0] as dynamic;
      final alertsData = results[1] as dynamic;
      final readingsData = results[2] as dynamic;
      final reportsData = results[3] as dynamic;

      final overviewMap = overviewData is Map ? Map<String, dynamic>.from(overviewData) : <String, dynamic>{};

      final alertsList = alertsData is Map && alertsData['items'] != null
          ? List<dynamic>.from(alertsData['items'])
          : alertsData is List
              ? List<dynamic>.from(alertsData)
              : <dynamic>[];

      final readingsList = readingsData is List
          ? List<dynamic>.from(readingsData)
          : readingsData is Map && readingsData['items'] != null
              ? List<dynamic>.from(readingsData['items'])
              : <dynamic>[];

      final reportsList = reportsData is Map && reportsData['items'] != null
          ? List<dynamic>.from(reportsData['items'])
          : reportsData is List
              ? List<dynamic>.from(reportsData)
              : <dynamic>[];

      state = state.copyWith(
        overview: overviewMap,
        alerts: alertsList,
        readings: readingsList,
        clinicalReports: reportsList,
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

final reportsProvider =
    StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsNotifier(apiClient);
});
