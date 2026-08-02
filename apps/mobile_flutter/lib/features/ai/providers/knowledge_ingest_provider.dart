import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_api_providers.dart';

class KnowledgeIngestState {
  final bool isIngesting;
  final Map<String, dynamic>? result;
  final String? error;

  const KnowledgeIngestState({
    this.isIngesting = false,
    this.result,
    this.error,
  });

  KnowledgeIngestState copyWith({
    bool? isIngesting,
    Map<String, dynamic>? result,
    String? error,
    bool clearError = false,
  }) {
    return KnowledgeIngestState(
      isIngesting: isIngesting ?? this.isIngesting,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class KnowledgeIngestNotifier extends StateNotifier<KnowledgeIngestState> {
  final AIApi _aiApi;

  KnowledgeIngestNotifier(this._aiApi) : super(const KnowledgeIngestState());

  Future<void> ingest(Map<String, dynamic> data) async {
    state = state.copyWith(isIngesting: true, error: null);
    try {
      final response = await _aiApi.ingestKnowledge(data);
      state = state.copyWith(
        isIngesting: false,
        result: response.data as Map<String, dynamic>?,
      );
    } catch (e) {
      state = state.copyWith(isIngesting: false, error: e.toString());
    }
  }

  void clear() {
    state = const KnowledgeIngestState();
  }
}

final knowledgeIngestProvider =
    StateNotifierProvider<KnowledgeIngestNotifier, KnowledgeIngestState>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  return KnowledgeIngestNotifier(aiApi);
});
