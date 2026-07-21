class KnowledgeSearchResponse {
  final List<Map<String, dynamic>> results;
  final int total;
  final double queryTimeMs;

  const KnowledgeSearchResponse({
    this.results = const [],
    this.total = 0,
    this.queryTimeMs = 0.0,
  });

  factory KnowledgeSearchResponse.fromJson(Map<String, dynamic> json) {
    return KnowledgeSearchResponse(
      results: (json['results'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      queryTimeMs: (json['query_time_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
