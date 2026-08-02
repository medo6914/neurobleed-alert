import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

class KnowledgeSearchState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> results;
  final List<Map<String, dynamic>> semanticResults;
  final String? query;
  final String? category;
  final int total;
  final double queryTimeMs;

  const KnowledgeSearchState({
    this.isLoading = false,
    this.error,
    this.results = const [],
    this.semanticResults = const [],
    this.query,
    this.category,
    this.total = 0,
    this.queryTimeMs = 0.0,
  });

  KnowledgeSearchState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? results,
    List<Map<String, dynamic>>? semanticResults,
    String? query,
    String? category,
    int? total,
    double? queryTimeMs,
    bool clearError = false,
  }) {
    return KnowledgeSearchState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      results: results ?? this.results,
      semanticResults: semanticResults ?? this.semanticResults,
      query: query ?? this.query,
      category: category ?? this.category,
      total: total ?? this.total,
      queryTimeMs: queryTimeMs ?? this.queryTimeMs,
    );
  }
}

class KnowledgeNotifier extends StateNotifier<KnowledgeSearchState> {
  final ApiClient _apiClient;

  KnowledgeNotifier(this._apiClient) : super(const KnowledgeSearchState());

  static const _categories = [
    'general',
    'clinical',
    'guideline',
    'research',
    'medication',
    'procedure',
    'anatomy',
    'pathology',
    'pubmed',
  ];

  List<String> get categories => _categories;

  Future<void> search(String query, {String? category}) async {
    if (query.trim().length < 2) return;

    state = state.copyWith(isLoading: true, error: null, query: query, category: category);

    try {
      final response = await _apiClient.post('/v1/ai/knowledge/search', data: {
        'query': query,
        'category': category,
        'limit': 20,
      });

      final data = response.data as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        results: (data['results'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        semanticResults: (data['semantic_results'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        total: (data['total'] as num?)?.toInt() ?? 0,
        queryTimeMs: (data['query_time_ms'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const KnowledgeSearchState();
  }
}

final knowledgeProvider = StateNotifierProvider<KnowledgeNotifier, KnowledgeSearchState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return KnowledgeNotifier(apiClient);
});

final knowledgeCategoriesProvider = Provider<List<String>>((ref) {
  return KnowledgeNotifier._categories;
});
