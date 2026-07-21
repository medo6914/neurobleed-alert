class DeviceUpdateRequest {
  final String? deviceName;
  final String? firmwareVersion;
  final String? hospitalId;
  final String? department;
  final String? status;

  const DeviceUpdateRequest({
    this.deviceName,
    this.firmwareVersion,
    this.hospitalId,
    this.department,
    this.status,
  });

  factory DeviceUpdateRequest.fromJson(Map<String, dynamic> json) =>
      DeviceUpdateRequest(
        deviceName: json['device_name'] as String?,
        firmwareVersion: json['firmware_version'] as String?,
        hospitalId: json['hospital_id'] as String?,
        department: json['department'] as String?,
        status: json['status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (deviceName != null) 'device_name': deviceName,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (hospitalId != null) 'hospital_id': hospitalId,
        if (department != null) 'department': department,
        if (status != null) 'status': status,
      };
}
