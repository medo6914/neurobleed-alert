class RiskAssessmentResponse {
  final double riskScore;
  final String riskLevel;
  final double confidence;
  final List<String> contributingFactors;
  final String? trend;
  final List<String> rulesTriggered;
  final String? modelVersion;
  final double inferenceTimeMs;

  const RiskAssessmentResponse({
    required this.riskScore,
    required this.riskLevel,
    required this.confidence,
    this.contributingFactors = const [],
    this.trend,
    this.rulesTriggered = const [],
    this.modelVersion,
    this.inferenceTimeMs = 0.0,
  });

  factory RiskAssessmentResponse.fromJson(Map<String, dynamic> json) {
    return RiskAssessmentResponse(
      riskScore: (json['risk_score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      contributingFactors: (json['contributing_factors'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      trend: json['trend'] as String?,
      rulesTriggered: (json['rules_triggered'] as List<dynamic>?)?.cast<String>() ?? [],
      modelVersion: json['model_version'] as String?,
      inferenceTimeMs: (json['inference_time_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get riskLabel {
    switch (riskLevel) {
      case 'critical':
        return 'Critical';
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  bool get isElevated => riskScore >= 0.6;
}
