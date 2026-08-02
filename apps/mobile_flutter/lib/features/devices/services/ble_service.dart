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
  BluetoothDevice? _connectedDevice;

  final StreamController<List<BleDevice>> _devicesController =
      StreamController<List<BleDevice>>.broadcast();
  final List<BleDevice> _discoveredDevices = [];

  Stream<List<BleDevice>> get devicesStream => _devicesController.stream;

  bool get isAvailable =>
      _state == BleState.poweredOn || _state == BleState.poweredOff;
  bool get isScanning => _state == BleState.scanning;
  BleState get state => _state;

  Future<bool> initialize() async {
    try {
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
      });

      final currentState = FlutterBluePlus.adapterStateNow;
      _state = currentState == BluetoothAdapterState.on
          ? BleState.poweredOn
          : BleState.poweredOff;
      return true;
    } catch (_) {
      _state = BleState.unsupported;
      return false;
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
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
    } catch (_) {
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

  Future<bool> connectToDevice(String deviceId) async {
    if (_connectedDevice != null) {
      return true;
    }

    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _adapterStateSub?.cancel();
    _scanResultsSub?.cancel();
    _connectedDevice?.disconnect();
    _devicesController.close();
  }
}
