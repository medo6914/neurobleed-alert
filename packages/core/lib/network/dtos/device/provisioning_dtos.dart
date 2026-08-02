class ProvisioningKeyCreateRequest {
  final String deviceType;
  final String? label;
  final String? hospitalId;
  final String? expiresAt;
  final int maxUses;

  const ProvisioningKeyCreateRequest({
    required this.deviceType,
    this.label,
    this.hospitalId,
    this.expiresAt,
    this.maxUses = 1,
  });

  Map<String, dynamic> toJson() => {
    'device_type': deviceType,
    if (label != null) 'label': label,
    if (hospitalId != null) 'hospital_id': hospitalId,
    if (expiresAt != null) 'expires_at': expiresAt,
    'max_uses': maxUses,
  };
}

class ProvisioningKey {
  final String id;
  final String key;
  final String deviceType;
  final String? label;
  final String status;
  final String? expiresAt;
  final String? usedAt;
  final int maxUses;
  final int useCount;
  final String createdAt;

  const ProvisioningKey({
    required this.id,
    required this.key,
    required this.deviceType,
    this.label,
    required this.status,
    this.expiresAt,
    this.usedAt,
    required this.maxUses,
    required this.useCount,
    required this.createdAt,
  });

  factory ProvisioningKey.fromJson(Map<String, dynamic> json) => ProvisioningKey(
    id: json['id'] as String,
    key: json['key'] as String,
    deviceType: json['device_type'] as String,
    label: json['label'] as String?,
    status: json['status'] as String,
    expiresAt: json['expires_at'] as String?,
    usedAt: json['used_at'] as String?,
    maxUses: (json['max_uses'] as num).toInt(),
    useCount: (json['use_count'] as num).toInt(),
    createdAt: json['created_at'] as String,
  );
}

class ProvisioningClaimRequest {
  final String provisioningKey;
  final String serialNumber;
  final String? deviceName;
  final String? deviceType;
  final String? macAddress;
  final String? firmwareVersion;
  final String? hardwareVersion;

  const ProvisioningClaimRequest({
    required this.provisioningKey,
    required this.serialNumber,
    this.deviceName,
    this.deviceType,
    this.macAddress,
    this.firmwareVersion,
    this.hardwareVersion,
  });

  Map<String, dynamic> toJson() => {
    'provisioning_key': provisioningKey,
    'serial_number': serialNumber,
    if (deviceName != null) 'device_name': deviceName,
    if (deviceType != null) 'device_type': deviceType,
    if (macAddress != null) 'mac_address': macAddress,
    if (firmwareVersion != null) 'firmware_version': firmwareVersion,
    if (hardwareVersion != null) 'hardware_version': hardwareVersion,
  };
}

class ProvisioningClaimResponse {
  final bool success;
  final String? deviceId;
  final String? serialNumber;
  final String message;
  final Map<String, dynamic>? device;

  const ProvisioningClaimResponse({
    required this.success,
    this.deviceId,
    this.serialNumber,
    required this.message,
    this.device,
  });

  factory ProvisioningClaimResponse.fromJson(Map<String, dynamic> json) => ProvisioningClaimResponse(
    success: json['success'] as bool,
    deviceId: json['device_id'] as String?,
    serialNumber: json['serial_number'] as String?,
    message: json['message'] as String,
    device: json['device'] as Map<String, dynamic>?,
  );
}
