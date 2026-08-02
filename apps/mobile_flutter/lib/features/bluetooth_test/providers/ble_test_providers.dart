import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ble_test_models.dart';
import '../services/real_ble_test_service.dart';

final bleTestServiceProvider = Provider<RealBleTestService>((ref) {
  final service = RealBleTestService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bleTestInitProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(bleTestServiceProvider);
  return service.initialize();
});

final bleTestScanStateProvider = StateProvider<bool>((ref) => false);

final bleTestScannedDevicesProvider = StreamProvider<List<BleTestDevice>>((ref) {
  final service = ref.watch(bleTestServiceProvider);
  return service.devicesStream;
});

final bleTestConnectionStateProvider = StreamProvider<BleTestConnectionState>((ref) {
  final service = ref.watch(bleTestServiceProvider);
  return service.connectionStream;
});

final bleTestServicesProvider = StreamProvider<List<BleTestServiceInfo>>((ref) {
  final service = ref.watch(bleTestServiceProvider);
  return service.servicesStream;
});

final bleTestLogsProvider = StreamProvider<List<BleTestLogEntry>>((ref) {
  final service = ref.watch(bleTestServiceProvider);
  return service.logsStream;
});

final bleTestNotificationProvider = StreamProvider<NotificationData>((ref) {
  final service = ref.watch(bleTestServiceProvider);
  return service.notificationStream;
});

final bleTestConnectedDeviceInfoProvider = Provider<({
  String? id,
  String? name,
  int? rssi,
  BleTestConnectionState state,
})>((ref) {
  final service = ref.watch(bleTestServiceProvider);
  return (
    id: service.connectedDeviceId,
    name: service.connectedDeviceName,
    rssi: service.connectedRssi,
    state: service.connectionState,
  );
});

final bleTestStatusProvider = Provider<({
  bool initialized,
  bool bleEnabled,
  bool locationPermission,
  bool nearbyPermission,
  bool scanning,
})>((ref) {
  final service = ref.watch(bleTestServiceProvider);
  return (
    initialized: service.isInitialized,
    bleEnabled: service.bleEnabled,
    locationPermission: service.locationPermissionGranted,
    nearbyPermission: service.nearbyDevicesPermissionGranted,
    scanning: service.isScanning,
  );
});
