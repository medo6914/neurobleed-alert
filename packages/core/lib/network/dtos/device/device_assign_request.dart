class DeviceAssignRequest {
  final String? patientId;
  final String? hospitalId;
  final String? department;

  const DeviceAssignRequest({
    this.patientId,
    this.hospitalId,
    this.department,
  });

  factory DeviceAssignRequest.fromJson(Map<String, dynamic> json) =>
      DeviceAssignRequest(
        patientId: json['patient_id'] as String?,
        hospitalId: json['hospital_id'] as String?,
        department: json['department'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (patientId != null) 'patient_id': patientId,
        if (hospitalId != null) 'hospital_id': hospitalId,
        if (department != null) 'department': department,
      };
}
