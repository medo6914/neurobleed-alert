class DashboardStatsDto {
  final int totalAssessments;
  final int totalAlerts;
  final String modelVersion;
  final bool modelTrained;
  final int ragDocumentCount;
  final bool ragIndexLoaded;
  final int activePatients;
  final int activeDevices;
  final double avgRiskScore;
  final Map<String, int> riskDistribution;
  final Map<String, int> alertsBySeverity;
  final List<Map<String, dynamic>> recentActivity;

  const DashboardStatsDto({
    this.totalAssessments = 0,
    this.totalAlerts = 0,
    this.modelVersion = '',
    this.modelTrained = false,
    this.ragDocumentCount = 0,
    this.ragIndexLoaded = false,
    this.activePatients = 0,
    this.activeDevices = 0,
    this.avgRiskScore = 0.0,
    this.riskDistribution = const {},
    this.alertsBySeverity = const {},
    this.recentActivity = const [],
  });

  factory DashboardStatsDto.fromJson(Map<String, dynamic> json) {
    final riskDist = (json['risk_distribution'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
        {};
    final alertsSev = (json['alerts_by_severity'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
        {};

    return DashboardStatsDto(
      totalAssessments: (json['total_assessments'] as num?)?.toInt() ?? 0,
      totalAlerts: (json['total_alerts'] as num?)?.toInt() ?? 0,
      modelVersion: json['model_version'] as String? ?? '',
      modelTrained: json['model_trained'] as bool? ?? false,
      ragDocumentCount: (json['rag_document_count'] as num?)?.toInt() ?? 0,
      ragIndexLoaded: json['rag_index_loaded'] as bool? ?? false,
      activePatients: (json['active_patients'] as num?)?.toInt() ?? 0,
      activeDevices: (json['active_devices'] as num?)?.toInt() ?? 0,
      avgRiskScore: (json['avg_risk_score'] as num?)?.toDouble() ?? 0.0,
      riskDistribution: riskDist,
      alertsBySeverity: alertsSev,
      recentActivity: (json['recent_activity'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
