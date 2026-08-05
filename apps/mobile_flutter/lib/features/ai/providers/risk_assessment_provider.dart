import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_api_providers.dart';

class RiskAssessmentState {
  final bool isAssessing;
  final RiskAssessmentResponse? result;
  final String? error;
  final List<RiskAssessmentResponse> history;
  final bool isLoadingHistory;

  const RiskAssessmentState({
    this.isAssessing = false,
    this.result,
    this.error,
    this.history = const [],
    this.isLoadingHistory = false,
  });

  RiskAssessmentState copyWith({
    bool? isAssessing,
    RiskAssessmentResponse? result,
    String? error,
    List<RiskAssessmentResponse>? history,
    bool? isLoadingHistory,
    bool clearError = false,
  }) {
    return RiskAssessmentState(
      isAssessing: isAssessing ?? this.isAssessing,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

class RiskAssessmentNotifier extends StateNotifier<RiskAssessmentState> {
  final AIApi _aiApi;

  RiskAssessmentNotifier(this._aiApi) : super(const RiskAssessmentState());

  Future<void> assessRisk({
    required String patientId,
    double? heartRate,
    double? spo2,
    double? rso2,
    double? systolicBp,
    double? diastolicBp,
    double? gcs,
    double signalQuality = 0.0,
    double motionArtifact = 0.0,
    List<Map<String, dynamic>>? readingsWindow,
  }) async {
    state = state.copyWith(isAssessing: true, error: null);
    try {
      final request = RiskAssessmentRequest(
        patientId: patientId,
        heartRate: heartRate,
        spo2: spo2,
        rso2: rso2,
        systolicBp: systolicBp,
        diastolicBp: diastolicBp,
        gcs: gcs,
        signalQuality: signalQuality,
        motionArtifact: motionArtifact,
        readingsWindow: readingsWindow,
      );
      final response = await _aiApi.assessRisk(request.toJson());
      final result = RiskAssessmentResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      state = state.copyWith(isAssessing: false, result: result);
    } catch (e) {
      state = state.copyWith(isAssessing: false, error: e.toString());
    }
  }

  Future<void> loadHistory(String patientId, {int limit = 50}) async {
    state = state.copyWith(isLoadingHistory: true, error: null);
    try {
      final response = await _aiApi.getRiskHistory(patientId, limit: limit);
      final list = (response.data as List<dynamic>)
          .map(
              (e) => RiskAssessmentResponse.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoadingHistory: false, history: list);
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false, error: e.toString());
    }
  }

  void clearResult() {
    state = state.copyWith(result: null, clearError: true);
  }
}

final riskAssessmentProvider =
    StateNotifierProvider<RiskAssessmentNotifier, RiskAssessmentState>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  return RiskAssessmentNotifier(aiApi);
});
