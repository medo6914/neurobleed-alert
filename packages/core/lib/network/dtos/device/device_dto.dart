class DeviceDto {
  final String id;
  final String? deviceName;
  final String? deviceType;
  final String serialNumber;
  final String? macAddress;
  final String? firmwareVersion;
  final String? hardwareVersion;
  final String? simIccid;
  final String? simStatus;
  final int? lteSignal;
  final String? wifiStatus;
  final double? batteryLevel;
  final bool? chargingStatus;
  final double? temperature;
  final int? signalStrength;
  final String? bleStatus;
  final String? status;
  final DateTime? lastSeen;
  final DateTime? lastHeartbeat;
  final DateTime? manufacturingDate;
  final DateTime? warrantyExpiry;
  final String? hospitalId;
  final String? patientId;
  final String? department;
  final String? certificateThumbprint;
  final bool? isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DeviceDto({
    required this.id,
    required this.serialNumber,
    this.deviceName,
    this.deviceType,
    this.macAddress,
    this.firmwareVersion,
    this.hardwareVersion,
    this.simIccid,
    this.simStatus,
    this.lteSignal,
    this.wifiStatus,
    this.batteryLevel,
    this.chargingStatus,
    this.temperature,
    this.signalStrength,
    this.bleStatus,
    this.status,
    this.lastSeen,
    this.lastHeartbeat,
    this.manufacturingDate,
    this.warrantyExpiry,
    this.hospitalId,
    this.patientId,
    this.department,
    this.certificateThumbprint,
    this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) => DeviceDto(
        id: json['id'] as String,
        serialNumber: json['serial_number'] as String,
        deviceName: json['device_name'] as String?,
        deviceType: json['device_type'] as String?,
        macAddress: json['mac_address'] as String?,
        firmwareVersion: json['firmware_version'] as String?,
        hardwareVersion: json['hardware_version'] as String?,
        simIccid: json['sim_iccid'] as String?,
        simStatus: json['sim_status'] as String?,
        lteSignal: json['lte_signal'] as int?,
        wifiStatus: json['wifi_status'] as String?,
        batteryLevel: (json['battery_level'] as num?)?.toDouble(),
        chargingStatus: json['charging_status'] as bool?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        signalStrength: json['signal_strength'] as int?,
        bleStatus: json['ble_status'] as String?,
        status: json['status'] as String?,
        lastSeen: json['last_seen'] != null
            ? DateTime.parse(json['last_seen'] as String)
            : null,
        lastHeartbeat: json['last_heartbeat'] != null
            ? DateTime.parse(json['last_heartbeat'] as String)
            : null,
        manufacturingDate: json['manufacturing_date'] != null
            ? DateTime.parse(json['manufacturing_date'] as String)
            : null,
        warrantyExpiry: json['warranty_expiry'] != null
            ? DateTime.parse(json['warranty_expiry'] as String)
            : null,
        hospitalId: json['hospital_id'] as String?,
        patientId: json['patient_id'] as String?,
        department: json['department'] as String?,
        certificateThumbprint: json['certificate_thumbprint'] as String?,
        isActive: json['is_active'] as bool?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serial_number': serialNumber,
        if (deviceName != null) 'device_name': deviceName,
        if (deviceType != null) 'device_type': deviceType,
        if (macAddress != null) 'mac_address': macAddress,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (hardwareVersion != null) 'hardware_version': hardwareVersion,
        if (simIccid != null) 'sim_iccid': simIccid,
        if (simStatus != null) 'sim_status': simStatus,
        if (lteSignal != null) 'lte_signal': lteSignal,
        if (wifiStatus != null) 'wifi_status': wifiStatus,
        if (batteryLevel != null) 'battery_level': batteryLevel,
        if (chargingStatus != null) 'charging_status': chargingStatus,
        if (temperature != null) 'temperature': temperature,
        if (signalStrength != null) 'signal_strength': signalStrength,
        if (bleStatus != null) 'ble_status': bleStatus,
        if (status != null) 'status': status,
        if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
        if (lastHeartbeat != null)
          'last_heartbeat': lastHeartbeat!.toIso8601String(),
        if (manufacturingDate != null)
          'manufacturing_date': manufacturingDate!.toIso8601String(),
        if (warrantyExpiry != null)
          'warranty_expiry': warrantyExpiry!.toIso8601String(),
        if (hospitalId != null) 'hospital_id': hospitalId,
        if (patientId != null) 'patient_id': patientId,
        if (department != null) 'department': department,
        if (certificateThumbprint != null)
          'certificate_thumbprint': certificateThumbprint,
        if (isActive != null) 'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}
