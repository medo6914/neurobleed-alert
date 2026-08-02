import 'dart:typed_data';

enum BleTestConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class BleTestDevice {
  final String id;
  final String name;
  final int rssi;
  final Map<String, dynamic> advertisementData;

  const BleTestDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.advertisementData = const {},
  });
}

class BleTestCharacteristic {
  final String uuid;
  final List<String> properties;
  final Uint8List? value;

  const BleTestCharacteristic({
    required this.uuid,
    this.properties = const [],
    this.value,
  });

  bool get isReadable => properties.contains('read');
  bool get isWritable => properties.contains('write') || properties.contains('writeWithoutResponse');
  bool get isNotifiable => properties.contains('notify');
  bool get isIndicatable => properties.contains('indicate');
}

class BleTestServiceInfo {
  final String uuid;
  final List<BleTestCharacteristic> characteristics;

  const BleTestServiceInfo({
    required this.uuid,
    this.characteristics = const [],
  });
}

class BleTestLogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  const BleTestLogEntry({
    required this.timestamp,
    required this.message,
    this.level = LogLevel.info,
  });
}

enum LogLevel { info, success, warning, error }

class NotificationData {
  final String characteristicUuid;
  final Uint8List data;
  final DateTime timestamp;

  const NotificationData({
    required this.characteristicUuid,
    required this.data,
    required this.timestamp,
  });
}
