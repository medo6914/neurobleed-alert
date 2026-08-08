import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum BleState { unknown, unsupported, poweredOff, poweredOn, scanning }

class BleDevice {
  final String id;
  final String name;
  final int rssi;

  const BleDevice({required this.id, required this.name, required this.rssi});
}

class BleService {
  BleState _state = BleState.unknown;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<List<ScanResult>>? _scanResultsSub;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSub;
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceName;
  bool _isConnecting = false;

  final StreamController<List<BleDevice>> _devicesController =
      StreamController<List<BleDevice>>.broadcast();
  final StreamController<BleState> _stateController =
      StreamController<BleState>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final List<BleDevice> _discoveredDevices = [];

  Stream<List<BleDevice>> get devicesStream => _devicesController.stream;
  Stream<BleState> get stateStream => _stateController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isAvailable =>
      _state == BleState.poweredOn || _state == BleState.poweredOff;
  bool get isScanning => _state == BleState.scanning;
  BleState get state => _state;
  bool get isConnected => _connectedDevice != null;
  bool get isConnecting => _isConnecting;
  String? get connectedDeviceId => _connectedDevice?.remoteId.str;
  String? get connectedDeviceName => _connectedDeviceName;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> initialize() async {
    try {
      _adapterStateSub?.cancel();
      _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
        switch (state) {
          case BluetoothAdapterState.on:
            _state = BleState.poweredOn;
          case BluetoothAdapterState.off:
            _state = BleState.poweredOff;
          case BluetoothAdapterState.unauthorized:
          case BluetoothAdapterState.unavailable:
          case BluetoothAdapterState.turningOff:
            _state = BleState.unsupported;
          case BluetoothAdapterState.unknown:
          case BluetoothAdapterState.turningOn:
            _state = BleState.unknown;
        }
        if (!_stateController.isClosed) {
          _stateController.add(_state);
        }
      });

      final currentState = FlutterBluePlus.adapterStateNow;
      _state = currentState == BluetoothAdapterState.on
          ? BleState.poweredOn
          : BleState.poweredOff;
      if (!_stateController.isClosed) _stateController.add(_state);
      return true;
    } catch (e) {
      _state = BleState.unsupported;
      return false;
    }
  }

  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (!isAvailable || _state == BleState.scanning) return;

    _state = BleState.scanning;
    _discoveredDevices.clear();
    _devicesController.add([]);

    try {
      _scanResultsSub?.cancel();
      _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final device = r.device;
          final id = device.remoteId.str;
          final name = device.advName.isNotEmpty
              ? device.advName
              : device.platformName.isNotEmpty
                  ? device.platformName
                  : 'Unknown';

          final index = _discoveredDevices.indexWhere((d) => d.id == id);
          final entry = BleDevice(id: id, name: name, rssi: r.rssi);
          if (index >= 0) {
            _discoveredDevices[index] = entry;
          } else {
            _discoveredDevices.add(entry);
          }
          _devicesController.add(List.unmodifiable(_discoveredDevices));
        }
      });

      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
        continuousUpdates: true,
      );
    } catch (e) {
      _state = BleState.poweredOn;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanResultsSub?.cancel();
    _scanResultsSub = null;
    _state = BleState.poweredOn;
  }

  Future<bool> connectToDevice(String deviceId,
      {String deviceName = 'Unknown'}) async {
    if (_isConnecting) return false;

    if (_connectedDevice != null) {
      if (_connectedDevice!.remoteId.str == deviceId) return true;
      await disconnect();
    }

    _isConnecting = true;
    _connectionController.add(false);

    try {
      final device = BluetoothDevice.fromId(deviceId);

      _connectionStateSub?.cancel();
      _connectionStateSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _connectedDeviceName = null;
          _isConnecting = false;
          _connectionController.add(false);
        }
      });

      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device;
      _connectedDeviceName = deviceName;
      _isConnecting = false;
      _connectionController.add(true);
      return true;
    } catch (e) {
      _connectedDevice = null;
      _connectedDeviceName = null;
      _isConnecting = false;
      _connectionController.add(false);
      return false;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    try {
      _connectionStateSub?.cancel();
      _connectionStateSub = null;
      await _connectedDevice!.disconnect();
    } catch (_) {}

    _connectedDevice = null;
    _connectedDeviceName = null;
    _isConnecting = false;
    _connectionController.add(false);
  }

  Future<List<BluetoothService>> discoverServices() async {
    if (_connectedDevice == null) return [];
    try {
      return await _connectedDevice!.discoverServices();
    } catch (e) {
      return [];
    }
  }

  Future<Uint8List?> readCharacteristic(
      String serviceUuid, String characteristicUuid) async {
    if (_connectedDevice == null) return null;

    for (final svc in await _connectedDevice!.servicesList) {
      if (svc.uuid.str == serviceUuid) {
        for (final ch in svc.characteristics) {
          if (ch.uuid.str == characteristicUuid && ch.properties.read) {
            try {
              final value = await ch.read();
              return Uint8List.fromList(value);
            } catch (_) {
              return null;
            }
          }
        }
      }
    }
    return null;
  }

  Future<bool> writeCharacteristic(
      String serviceUuid, String characteristicUuid, List<int> data,
      {bool withResponse = true}) async {
    if (_connectedDevice == null) return false;

    for (final svc in await _connectedDevice!.servicesList) {
      if (svc.uuid.str == serviceUuid) {
        for (final ch in svc.characteristics) {
          if (ch.uuid.str == characteristicUuid) {
            if (withResponse && !ch.properties.write) return false;
            if (!withResponse && !ch.properties.writeWithoutResponse) {
              return false;
            }
            try {
              await ch.write(data, withoutResponse: !withResponse);
              return true;
            } catch (_) {
              return false;
            }
          }
        }
      }
    }
    return false;
  }

  Future<Stream<List<int>>?> enableNotifications(
      String serviceUuid, String characteristicUuid) async {
    if (_connectedDevice == null) return null;

    for (final svc in await _connectedDevice!.servicesList) {
      if (svc.uuid.str == serviceUuid) {
        for (final ch in svc.characteristics) {
          if (ch.uuid.str == characteristicUuid &&
              (ch.properties.notify || ch.properties.indicate)) {
            try {
              await ch.setNotifyValue(true);
              return ch.lastValueStream;
            } catch (_) {
              return null;
            }
          }
        }
      }
    }
    return null;
  }

  Future<bool> disableNotifications(String characteristicUuid) async {
    if (_connectedDevice == null) return false;

    for (final svc in await _connectedDevice!.servicesList) {
      for (final ch in svc.characteristics) {
        if (ch.uuid.str == characteristicUuid) {
          try {
            await ch.setNotifyValue(false);
            return true;
          } catch (_) {
            return false;
          }
        }
      }
    }
    return false;
  }

  void dispose() {
    _adapterStateSub?.cancel();
    _scanResultsSub?.cancel();
    _connectionStateSub?.cancel();
    try {
      _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _connectedDeviceName = null;
    if (!_devicesController.isClosed) _devicesController.close();
    if (!_stateController.isClosed) _stateController.close();
    if (!_connectionController.isClosed) _connectionController.close();
  }
}
