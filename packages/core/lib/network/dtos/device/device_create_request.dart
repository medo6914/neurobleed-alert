class DeviceCreateRequest {
  final String serialNumber;
  final String? deviceName;
  final String? deviceType;
  final String? macAddress;
  final String? firmwareVersion;
  final String? hardwareVersion;
  final String? hospitalId;
  final String? department;

  const DeviceCreateRequest({
    required this.serialNumber,
    this.deviceName,
    this.deviceType,
    this.macAddress,
    this.firmwareVersion,
    this.hardwareVersion,
    this.hospitalId,
    this.department,
  });

  factory DeviceCreateRequest.fromJson(Map<String, dynamic> json) =>
      DeviceCreateRequest(
        serialNumber: json['serial_number'] as String,
        deviceName: json['device_name'] as String?,
        deviceType: json['device_type'] as String?,
        macAddress: json['mac_address'] as String?,
        firmwareVersion: json['firmware_version'] as String?,
        hardwareVersion: json['hardware_version'] as String?,
        hospitalId: json['hospital_id'] as String?,
        department: json['department'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'serial_number': serialNumber,
        if (deviceName != null) 'device_name': deviceName,
        if (deviceType != null) 'device_type': deviceType,
        if (macAddress != null) 'mac_address': macAddress,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (hardwareVersion != null) 'hardware_version': hardwareVersion,
        if (hospitalId != null) 'hospital_id': hospitalId,
        if (department != null) 'department': department,
      };
}
