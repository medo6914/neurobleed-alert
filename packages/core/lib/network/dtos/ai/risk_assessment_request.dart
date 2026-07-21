class RiskAssessmentRequest {
  final String patientId;
  final double? heartRate;
  final double? spo2;
  final double? rso2;
  final double? irValue;
  final double? redValue;
  final double? systolicBp;
  final double? diastolicBp;
  final double? gcs;
  final double signalQuality;
  final double motionArtifact;
  final List<Map<String, dynamic>>? readingsWindow;

  const RiskAssessmentRequest({
    required this.patientId,
    this.heartRate,
    this.spo2,
    this.rso2,
    this.irValue,
    this.redValue,
    this.systolicBp,
    this.diastolicBp,
    this.gcs,
    this.signalQuality = 0.0,
    this.motionArtifact = 0.0,
    this.readingsWindow,
  });

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'heart_rate': heartRate,
      'spo2': spo2,
      'rso2': rso2,
      'ir_value': irValue,
      'red_value': redValue,
      'systolic_bp': systolicBp,
      'diastolic_bp': diastolicBp,
      'gcs': gcs,
      'signal_quality': signalQuality,
      'motion_artifact': motionArtifact,
      if (readingsWindow != null) 'readings_window': readingsWindow,
    };
  }
}
