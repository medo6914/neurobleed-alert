class ModelStatusDto {
  final String status;
  final double progress;
  final String message;
  final bool modelExists;
  final String modelPath;
  final String? startedAt;
  final String? completedAt;

  const ModelStatusDto({
    required this.status,
    required this.progress,
    this.message = '',
    this.modelExists = false,
    this.modelPath = '',
    this.startedAt,
    this.completedAt,
  });

  factory ModelStatusDto.fromJson(Map<String, dynamic> json) {
    return ModelStatusDto(
      status: json['status'] as String? ?? 'idle',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      modelExists: json['model_exists'] as bool? ?? false,
      modelPath: json['model_path'] as String? ?? '',
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }
}
