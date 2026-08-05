import 'risk_assessment_response.dart';

class BatchRiskResponse {
  final List<RiskAssessmentResponse> assessments;
  final double aggregateScore;
  final String aggregateLevel;
  final String trend;

  const BatchRiskResponse({
    required this.assessments,
    required this.aggregateScore,
    required this.aggregateLevel,
    required this.trend,
  });

  factory BatchRiskResponse.fromJson(Map<String, dynamic> json) {
    return BatchRiskResponse(
      assessments: (json['assessments'] as List<dynamic>)
          .map(
              (e) => RiskAssessmentResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      aggregateScore: (json['aggregate_score'] as num).toDouble(),
      aggregateLevel: json['aggregate_level'] as String,
      trend: json['trend'] as String,
    );
  }
}
