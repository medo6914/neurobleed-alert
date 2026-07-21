class DeviceDiagnostics {
  final String deviceId;
  final String? status;
  final double? batteryLevel;
  final int? signalStrength;
  final String? firmwareVersion;
  final String? hardwareVersion;
  final double? temperature;
  final bool? chargingStatus;
  final int? lteSignal;
  final String? simStatus;
  final String? bleStatus;
  final DateTime? lastSeen;
  final int? uptime;

  const DeviceDiagnostics({
    required this.deviceId,
    this.status,
    this.batteryLevel,
    this.signalStrength,
    this.firmwareVersion,
    this.hardwareVersion,
    this.temperature,
    this.chargingStatus,
    this.lteSignal,
    this.simStatus,
    this.bleStatus,
    this.lastSeen,
    this.uptime,
  });

  factory DeviceDiagnostics.fromJson(Map<String, dynamic> json) =>
      DeviceDiagnostics(
        deviceId: json['device_id'] as String,
        status: json['status'] as String?,
        batteryLevel: (json['battery_level'] as num?)?.toDouble(),
        signalStrength: json['signal_strength'] as int?,
        firmwareVersion: json['firmware_version'] as String?,
        hardwareVersion: json['hardware_version'] as String?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        chargingStatus: json['charging_status'] as bool?,
        lteSignal: json['lte_signal'] as int?,
        simStatus: json['sim_status'] as String?,
        bleStatus: json['ble_status'] as String?,
        lastSeen: json['last_seen'] != null
            ? DateTime.parse(json['last_seen'] as String)
            : null,
        uptime: json['uptime'] as int?,
      );
}
