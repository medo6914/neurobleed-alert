import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class WebBleDevice {
  final String id;
  final String name;
  final int rssi;

  const WebBleDevice({required this.id, required this.name, required this.rssi});
}

class WebBleService {
  web.BluetoothDevice? _device;
  StreamSubscription<List<int>>? _notificationSubscription;
  
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  
  bool get isConnected => _device != null;

  Future<bool> initialize() async {
    try {
      // Check if Web Bluetooth is available
      final nav = web.window.navigator;
      final bluetooth = nav.bluetooth;
      if (bluetooth == null) {
        debugPrint('[WebBLE] Bluetooth not available');
        return false;
      }
      
      final available = await bluetooth.getAvailability().toDart;
      debugPrint('[WebBLE] Bluetooth available: $available');
      return available;
    } catch (e) {
      debugPrint('[WebBLE] Initialize error: $e');
      return false;
    }
  }

  Future<WebBleDevice?> scanAndConnect() async {
    try {
      final nav = web.window.navigator;
      final bluetooth = nav.bluetooth;
      
      if (bluetooth == null) {
        debugPrint('[WebBLE] Bluetooth not available');
        return null;
      }

      // Request device with NeuroBleed service UUID
      final options = web.BluetoothRequestOptions(
        filters: [
          web.BluetoothScanFilter(
            services: ['0000fff0-0000-1000-8000-00805f9b34fb'], // NeuroBleed service UUID
          ),
        ],
        optionalServices: ['0000fff0-0000-1000-8000-00805f9b34fb'],
      );

      final device = await bluetooth.requestDevice(options: options).toDart;
      
      if (device != null) {
        _device = device;
        _connectionController.add(true);
        
        // Get device info
        final id = device.id ?? 'unknown';
        final name = device.name ?? 'NeuroBleed Device';
        
        debugPrint('[WebBLE] Connected to: $name ($id)');
        
        return WebBleDevice(
          id: id,
          name: name,
          rssi: -50, // Default RSSI for web
        );
      }
    } catch (e) {
      debugPrint('[WebBLE] Scan/Connect error: $e');
    }
    
    return null;
  }

  Future<bool> connect() async {
    if (_device == null) return false;
    
    try {
      final gatt = _device!.gatt;
      if (gatt == null) {
        debugPrint('[WebBLE] GATT not available');
        return false;
      }

      final server = await gatt.connect().toDart;
      debugPrint('[WebBLE] GATT connected');
      
      // Discover services
      final services = await server.getPrimaryServices().toDart;
      debugPrint('[WebBLE] Found ${services.length} services');
      
      return true;
    } catch (e) {
      debugPrint('[WebBLE] Connect error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      _notificationSubscription?.cancel();
      _device?.gatt?.disconnect();
      _device = null;
      _connectionController.add(false);
    } catch (e) {
      debugPrint('[WebBLE] Disconnect error: $e');
    }
  }

  Future<Map<String, dynamic>?> readData() async {
    if (_device?.gatt == null) return null;
    
    try {
      final server = await _device!.gatt!.connect().toDart;
      final services = await server.getPrimaryServices().toDart;
      
      if (services.isEmpty) return null;
      
      final service = services.first;
      final characteristics = await service.getCharacteristics().toDart;
      
      if (characteristics.isEmpty) return null;
      
      // Try to read the first characteristic
      final char = characteristics.first;
      if (char.properties.read) {
        final value = await char.readValue().toDart;
        debugPrint('[WebBLE] Read value: $value');
        
        // Parse the data (simplified)
        return {
          'heart_rate': value.isNotEmpty ? value[0] : 0,
          'spo2': value.length > 1 ? value[1] : 0,
          'temperature': value.length > 2 ? value[2] / 10.0 : 0.0,
          'brain_flow': value.length > 3 ? value[3] : 0,
        };
      }
    } catch (e) {
      debugPrint('[WebBLE] Read error: $e');
    }
    
    return null;
  }

  Future<void> enableNotifications() async {
    if (_device?.gatt == null) return;
    
    try {
      final server = await _device!.gatt!.connect().toDart;
      final services = await server.getPrimaryServices().toDart;
      
      for (final service in services) {
        final characteristics = await service.getCharacteristics().toDart;
        
        for (final char in characteristics) {
          if (char.properties.notify) {
            await char.startNotifications().toDart;
            
            char.addEventListener('characteristicvaluechanged', (event) {
              final target = (event as web.Event).target as web.BluetoothCharacteristic;
              final value = target.value;
              if (value != null) {
                // Parse and emit data
                _dataController.add({
                  'heart_rate': value.isNotEmpty ? value[0] : 0,
                  'spo2': value.length > 1 ? value[1] : 0,
                  'temperature': value.length > 2 ? value[2] / 10.0 : 0.0,
                  'brain_flow': value.length > 3 ? value[3] : 0,
                  'timestamp': DateTime.now().toIso8601String(),
                });
              }
            });
            
            debugPrint('[WebBLE] Notifications enabled on ${char.uuid}');
          }
        }
      }
    } catch (e) {
      debugPrint('[WebBLE] Enable notifications error: $e');
    }
  }

  void dispose() {
    _notificationSubscription?.cancel();
    disconnect();
    _connectionController.close();
    _dataController.close();
  }
}
