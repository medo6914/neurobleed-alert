import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide LogLevel;
import '../models/ble_test_models.dart';

class RealBleTestService {
  BleTestConnectionState _connectionState = BleTestConnectionState.disconnected;
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  int? _connectedRssi;
  final List<BleTestDevice> _discoveredDevices = [];
  final List<BleTestServiceInfo> _discoveredServices = [];
  final List<BleTestLogEntry> _logs = [];
  bool _isScanning = false;
  bool _isInitialized = false;
  bool _bleEnabled = true;
  bool _locationPermissionGranted = false;
  bool _nearbyDevicesPermissionGranted = false;

  final StreamController<List<BleTestDevice>> _devicesController =
      StreamController<List<BleTestDevice>>.broadcast();
  final StreamController<BleTestConnectionState> _connectionController =
      StreamController<BleTestConnectionState>.broadcast();
  final StreamController<List<BleTestServiceInfo>> _servicesController =
      StreamController<List<BleTestServiceInfo>>.broadcast();
  final StreamController<NotificationData> _notificationController =
      StreamController<NotificationData>.broadcast();
  final StreamController<List<BleTestLogEntry>> _logsController =
      StreamController<List<BleTestLogEntry>>.broadcast();

  StreamSubscription? _adapterStateSub;
  StreamSubscription? _scanResultsSub;
  StreamSubscription? _connectionStateSub;
  final List<StreamSubscription> _deviceSubscriptions = [];

  BluetoothDevice? _connectedDevice;
  final Map<String, BluetoothCharacteristic> _notifyCharacteristics = {};

  Stream<List<BleTestDevice>> get devicesStream => _devicesController.stream;
  Stream<BleTestConnectionState> get connectionStream =>
      _connectionController.stream;
  Stream<List<BleTestServiceInfo>> get servicesStream =>
      _servicesController.stream;
  Stream<NotificationData> get notificationStream =>
      _notificationController.stream;
  Stream<List<BleTestLogEntry>> get logsStream => _logsController.stream;

  BleTestConnectionState get connectionState => _connectionState;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectedDeviceName => _connectedDeviceName;
  int? get connectedRssi => _connectedRssi;
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  bool get bleEnabled => _bleEnabled;
  bool get locationPermissionGranted => _locationPermissionGranted;
  bool get nearbyDevicesPermissionGranted => _nearbyDevicesPermissionGranted;
  List<BleTestServiceInfo> get discoveredServices =>
      List.unmodifiable(_discoveredServices);
  List<BleTestLogEntry> get logs => List.unmodifiable(_logs);

  void _addLog(String message, {LogLevel level = LogLevel.info}) {
    final entry = BleTestLogEntry(
        timestamp: DateTime.now(), message: message, level: level);
    _logs.add(entry);
    _logsController.add(List.unmodifiable(_logs));
  }

  Future<bool> initialize() async {
    try {
      _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
        _bleEnabled = state == BluetoothAdapterState.on;
        _addLog('Adapter state: ${state.name}', level: LogLevel.info);
      });

      final state = FlutterBluePlus.adapterStateNow;
      _bleEnabled = state == BluetoothAdapterState.on;
      _isInitialized = true;
      _addLog('Real BLE service initialized (state: ${state.name})',
          level: LogLevel.success);
      return true;
    } catch (e) {
      _isInitialized = false;
      _addLog('BLE initialization failed: $e', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
      _bleEnabled = true;
      _addLog('Bluetooth enabled', level: LogLevel.success);
      return true;
    } catch (e) {
      _addLog('Failed to enable Bluetooth: $e', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        _addLog('BLE not supported on this device', level: LogLevel.error);
        return false;
      }
      _locationPermissionGranted = true;
      _nearbyDevicesPermissionGranted = true;
      _addLog('Permissions verified', level: LogLevel.success);
      return true;
    } catch (e) {
      _addLog('Permission request failed: $e', level: LogLevel.error);
      return false;
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (_isScanning) return;
    if (!_bleEnabled) {
      _addLog('Cannot scan: Bluetooth is off', level: LogLevel.error);
      return;
    }

    _isScanning = true;
    _discoveredDevices.clear();
    _devicesController.add([]);
    _addLog('Scan started (timeout: ${timeout.inSeconds}s)',
        level: LogLevel.info);

    try {
      _scanResultsSub?.cancel();
      _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          _addOrUpdateDevice(r);
        }
      });

      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
        continuousUpdates: true,
      );
    } catch (e) {
      _addLog('Scan error: $e', level: LogLevel.error);
      _isScanning = false;
    }
  }

  void _addOrUpdateDevice(ScanResult result) {
    final device = result.device;
    final id = device.remoteId.str;

    final advData = result.advertisementData;
    final name = device.advName.isNotEmpty
        ? device.advName
        : device.platformName.isNotEmpty
            ? device.platformName
            : 'Unknown';

    final advertisementFields = <String, dynamic>{};
    if (advData.txPowerLevel != null) {
      advertisementFields['tx_power'] = advData.txPowerLevel;
    }
    if (advData.manufacturerData.isNotEmpty) {
      advertisementFields['manufacturer_data'] =
          advData.manufacturerData.length;
    }
    if (advData.serviceUuids.isNotEmpty) {
      advertisementFields['service_uuids'] =
          advData.serviceUuids.map((g) => g.str).toList();
    }

    final index = _discoveredDevices.indexWhere((d) => d.id == id);
    if (index >= 0) {
      _discoveredDevices[index] = BleTestDevice(
        id: id,
        name: name,
        rssi: result.rssi,
        advertisementData: advertisementFields,
      );
    } else {
      _discoveredDevices.add(BleTestDevice(
        id: id,
        name: name,
        rssi: result.rssi,
        advertisementData: advertisementFields,
      ));
      _addLog('Device found: $name ($id, RSSI: ${result.rssi})',
          level: LogLevel.success);
    }
    _devicesController.add(List.unmodifiable(_discoveredDevices));
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanResultsSub?.cancel();
      _scanResultsSub = null;
    } catch (_) {}
    _isScanning = false;
    _addLog('Scan stopped (devices found: ${_discoveredDevices.length})',
        level: LogLevel.info);
  }

  Future<bool> connectToDevice(String deviceId,
      {String deviceName = 'Unknown'}) async {
    if (_connectionState == BleTestConnectionState.connected) {
      _addLog('Already connected to $_connectedDeviceName',
          level: LogLevel.warning);
      return true;
    }

    final scanResult = _discoveredDevices.where((d) => d.id == deviceId);
    if (scanResult.isEmpty) {
      _addLog('Device $deviceName not found in scan results',
          level: LogLevel.error);
      return false;
    }

    _connectionState = BleTestConnectionState.connecting;
    _connectionController.add(_connectionState);
    _addLog('Connecting to $deviceName ($deviceId)...', level: LogLevel.info);

    try {
      final device = BluetoothDevice.fromId(deviceId);

      _connectionStateSub?.cancel();
      _connectionStateSub =
          device.connectionState.listen((state) {
        _handleConnectionStateChange(state, deviceId, deviceName);
      });

      await device.connect(timeout: const Duration(seconds: 15));

      final rssiResult = _discoveredDevices
          .where((d) => d.id == deviceId)
          .map((d) => d.rssi)
          .firstOrNull;

      _connectedDevice = device;
      _connectedDeviceId = deviceId;
      _connectedDeviceName = deviceName;
      _connectedRssi = rssiResult;
      _connectionState = BleTestConnectionState.connected;
      _connectionController.add(_connectionState);
      _addLog('Connected to $deviceName', level: LogLevel.success);
      return true;
    } catch (e) {
      _connectionState = BleTestConnectionState.disconnected;
      _connectionController.add(_connectionState);
      _addLog('Connection failed: $e', level: LogLevel.error);
      return false;
    }
  }

  void _handleConnectionStateChange(
      BluetoothConnectionState state, String deviceId, String deviceName) {
    switch (state) {
      case BluetoothConnectionState.disconnected:
        if (_connectionState == BleTestConnectionState.connected ||
            _connectionState == BleTestConnectionState.connecting) {
          _connectionState = BleTestConnectionState.disconnected;
          _connectionController.add(_connectionState);
          _connectedDevice = null;
          _connectedDeviceId = null;
          _connectedDeviceName = null;
          _connectedRssi = null;
          _discoveredServices.clear();
          _servicesController.add([]);
          _addLog('Disconnected from $deviceName', level: LogLevel.warning);
        }
      default:
        break;
    }
  }

  Future<void> disconnect() async {
    if (_connectionState == BleTestConnectionState.disconnected) return;

    _connectionState = BleTestConnectionState.disconnecting;
    _connectionController.add(_connectionState);
    _addLog('Disconnecting from $_connectedDeviceName...', level: LogLevel.info);

    try {
      await _connectedDevice?.disconnect();
      _connectionStateSub?.cancel();
      _connectionStateSub = null;

      for (final sub in _deviceSubscriptions) {
        sub.cancel();
      }
      _deviceSubscriptions.clear();
      _notifyCharacteristics.clear();

      _connectedDevice = null;
      _connectedDeviceId = null;
      _connectedDeviceName = null;
      _connectedRssi = null;
      _discoveredServices.clear();
      _connectionState = BleTestConnectionState.disconnected;
      _connectionController.add(_connectionState);
      _servicesController.add([]);
      _addLog('Disconnected', level: LogLevel.success);
    } catch (e) {
      _addLog('Disconnect error: $e', level: LogLevel.error);
      _connectionState = BleTestConnectionState.disconnected;
      _connectionController.add(_connectionState);
    }
  }

  Future<List<BleTestServiceInfo>> discoverServices() async {
    if (_connectionState != BleTestConnectionState.connected) {
      _addLog('Cannot discover services: not connected', level: LogLevel.error);
      return [];
    }

    final device = _connectedDevice;
    if (device == null) {
      _addLog('Cannot discover services: no device reference',
          level: LogLevel.error);
      return [];
    }

    _addLog('Discovering services...', level: LogLevel.info);

    try {
      await device.discoverServices();
      await Future.delayed(const Duration(milliseconds: 500));

      _discoveredServices.clear();

      for (final svc in device.servicesList) {
        final characteristics = <BleTestCharacteristic>[];
        for (final ch in svc.characteristics) {
          final props = <String>[];
          if (ch.properties.read) props.add('read');
          if (ch.properties.write) props.add('write');
          if (ch.properties.writeWithoutResponse) {
            props.add('writeWithoutResponse');
          }
          if (ch.properties.notify) props.add('notify');
          if (ch.properties.indicate) props.add('indicate');

          characteristics.add(BleTestCharacteristic(
            uuid: ch.uuid.str,
            properties: props,
          ));
        }

        _discoveredServices.add(BleTestServiceInfo(
          uuid: svc.uuid.str,
          characteristics: characteristics,
        ));

        _addLog(
            'Service ${svc.uuid.str} (${characteristics.length} characteristics)',
            level: LogLevel.success);
      }

      _servicesController.add(List.unmodifiable(_discoveredServices));
      _addLog('Services discovered: ${_discoveredServices.length}',
          level: LogLevel.success);
      return List.unmodifiable(_discoveredServices);
    } catch (e) {
      _addLog('Service discovery failed: $e', level: LogLevel.error);
      return [];
    }
  }

  BluetoothCharacteristic? _findCharacteristic(
      String characteristicUuid) {
    final device = _connectedDevice;
    if (device == null) return null;

    for (final svc in device.servicesList) {
      for (final ch in svc.characteristics) {
        if (ch.uuid.str == characteristicUuid) {
          return ch;
        }
      }
    }
    return null;
  }

  Future<Uint8List?> readCharacteristic(
      String serviceUuid, String characteristicUuid) async {
    if (_connectionState != BleTestConnectionState.connected) {
      _addLog('Cannot read: not connected', level: LogLevel.error);
      return null;
    }

    final ch = _findCharacteristic(characteristicUuid);
    if (ch == null) {
      _addLog('Characteristic $characteristicUuid not found',
          level: LogLevel.warning);
      return null;
    }

    if (!ch.properties.read) {
      _addLog('Characteristic $characteristicUuid does not support read',
          level: LogLevel.warning);
      return null;
    }

    _addLog('Reading $characteristicUuid...', level: LogLevel.info);

    try {
      final value = await ch.read();
      _addLog('Read $characteristicUuid: ${value.length} bytes',
          level: LogLevel.success);
      return Uint8List.fromList(value);
    } catch (e) {
      _addLog('Read failed: $e', level: LogLevel.error);
      return null;
    }
  }

  Future<bool> writeCharacteristic(String serviceUuid,
      String characteristicUuid, Uint8List data,
      {bool withResponse = true}) async {
    if (_connectionState != BleTestConnectionState.connected) {
      _addLog('Cannot write: not connected', level: LogLevel.error);
      return false;
    }

    final ch = _findCharacteristic(characteristicUuid);
    if (ch == null) {
      _addLog('Characteristic $characteristicUuid not found',
          level: LogLevel.warning);
      return false;
    }

    if (withResponse && !ch.properties.write) {
      _addLog('Characteristic $characteristicUuid does not support write with response',
          level: LogLevel.warning);
      return false;
    }
    if (!withResponse && !ch.properties.writeWithoutResponse) {
      _addLog('Characteristic $characteristicUuid does not support write without response',
          level: LogLevel.warning);
      return false;
    }

    final hex =
        data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    final ascii = utf8.decode(data, allowMalformed: true);
    _addLog(
        'Writing to $characteristicUuid: HEX=[$hex] ASCII=[$ascii]${withResponse ? "" : " (no response)"}',
        level: LogLevel.info);

    try {
      await ch.write(data.toList(),
          withoutResponse: !withResponse);
      _addLog('Write successful', level: LogLevel.success);
      return true;
    } catch (e) {
      _addLog('Write failed: $e', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> enableNotifications(
      String serviceUuid, String characteristicUuid) async {
    if (_connectionState != BleTestConnectionState.connected) {
      _addLog('Cannot enable notifications: not connected',
          level: LogLevel.error);
      return false;
    }

    final ch = _findCharacteristic(characteristicUuid);
    if (ch == null) {
      _addLog('Characteristic $characteristicUuid not found',
          level: LogLevel.warning);
      return false;
    }

    if (!ch.properties.notify && !ch.properties.indicate) {
      _addLog('Characteristic $characteristicUuid does not support notify/indicate',
          level: LogLevel.warning);
      return false;
    }

    _addLog('Enabling notifications on $characteristicUuid...',
        level: LogLevel.info);

    try {
      final sub = ch.lastValueStream.listen((value) {
        final notification = NotificationData(
          characteristicUuid: characteristicUuid,
          data: Uint8List.fromList(value),
          timestamp: DateTime.now(),
        );
        _notificationController.add(notification);
        _addLog(
            'Notification from $characteristicUuid: ${value.length} bytes',
            level: LogLevel.success);
      });
      _deviceSubscriptions.add(sub);
      _notifyCharacteristics[characteristicUuid] = ch;

      await ch.setNotifyValue(true);
      _addLog('Notifications enabled on $characteristicUuid',
          level: LogLevel.success);
      return true;
    } catch (e) {
      _addLog('Enable notifications failed: $e', level: LogLevel.error);
      return false;
    }
  }

  Future<bool> disableNotifications(String characteristicUuid) async {
    final ch = _notifyCharacteristics[characteristicUuid];
    if (ch == null) {
      _addLog('Notifications not active on $characteristicUuid',
          level: LogLevel.warning);
      return false;
    }

    _addLog('Disabling notifications on $characteristicUuid...',
        level: LogLevel.info);

    try {
      await ch.setNotifyValue(false);
      _notifyCharacteristics.remove(characteristicUuid);
      _addLog('Notifications disabled on $characteristicUuid',
          level: LogLevel.success);
      return true;
    } catch (e) {
      _addLog('Disable notifications failed: $e', level: LogLevel.error);
      return false;
    }
  }

  void clearLogs() {
    _logs.clear();
    _logsController.add([]);
  }

  String exportLogs() {
    return _logs.map((entry) {
      final ts =
          '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
      return '[$ts] [${entry.level.name.toUpperCase()}] ${entry.message}';
    }).join('\n');
  }

  void dispose() {
    _adapterStateSub?.cancel();
    _scanResultsSub?.cancel();
    _connectionStateSub?.cancel();
    for (final sub in _deviceSubscriptions) {
      sub.cancel();
    }
    _deviceSubscriptions.clear();
    _notifyCharacteristics.clear();
    _devicesController.close();
    _connectionController.close();
    _servicesController.close();
    _notificationController.close();
    _logsController.close();
  }
}
