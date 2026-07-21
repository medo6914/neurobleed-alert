class DeviceStatusUpdate {
  final String? status;
  final double? batteryLevel;
  final int? signalStrength;
  final double? temperature;
  final bool? chargingStatus;
  final int? lteSignal;
  final String? simStatus;
  final String? bleStatus;

  const DeviceStatusUpdate({
    this.status,
    this.batteryLevel,
    this.signalStrength,
    this.temperature,
    this.chargingStatus,
    this.lteSignal,
    this.simStatus,
    this.bleStatus,
  });

  factory DeviceStatusUpdate.fromJson(Map<String, dynamic> json) =>
      DeviceStatusUpdate(
        status: json['status'] as String?,
        batteryLevel: (json['battery_level'] as num?)?.toDouble(),
        signalStrength: json['signal_strength'] as int?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        chargingStatus: json['charging_status'] as bool?,
        lteSignal: json['lte_signal'] as int?,
        simStatus: json['sim_status'] as String?,
        bleStatus: json['ble_status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status,
        if (batteryLevel != null) 'battery_level': batteryLevel,
        if (signalStrength != null) 'signal_strength': signalStrength,
        if (temperature != null) 'temperature': temperature,
        if (chargingStatus != null) 'charging_status': chargingStatus,
        if (lteSignal != null) 'lte_signal': lteSignal,
        if (simStatus != null) 'sim_status': simStatus,
        if (bleStatus != null) 'ble_status': bleStatus,
      };
}
