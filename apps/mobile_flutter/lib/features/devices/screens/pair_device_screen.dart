import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../services/ble_service.dart';
import '../../../app/providers/app_providers.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  final service = BleService();
  ref.onDispose(() => service.dispose());
  return service;
});

final bleScanStateProvider = StateProvider<bool>((ref) => false);

final bleDevicesProvider = StreamProvider<List<BleDevice>>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.devicesStream;
});

final bleConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionStream;
});

class PairDeviceScreen extends ConsumerStatefulWidget {
  final String? deviceId;

  const PairDeviceScreen({super.key, this.deviceId});

  @override
  ConsumerState<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends ConsumerState<PairDeviceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimation;
  String? _pairingDeviceId;
  bool _isPairing = false;

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _scanAnimation.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    final service = ref.read(bleServiceProvider);
    ref.read(bleScanStateProvider.notifier).state = true;
    _scanAnimation.repeat();
    await service.initialize();
    await service.startScan();
  }

  void _stopScan() {
    final service = ref.read(bleServiceProvider);
    service.stopScan();
    ref.read(bleScanStateProvider.notifier).state = false;
    _scanAnimation.stop();
    _scanAnimation.reset();
  }

  Future<void> _pairDevice(BleDevice device) async {
    setState(() {
      _pairingDeviceId = device.id;
      _isPairing = true;
    });

    final service = ref.read(bleServiceProvider);

    // Step 1: Auto-register device on backend
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/v1/devices/', data: {
        'serial_number': device.id,
        'device_name': device.name,
        'device_type': 'NB-01',
        'mac_address': device.id,
      });
    } catch (e) {
      // Device might already exist - that's OK, continue to connect
    }

    // Step 2: Connect via BLE
    final success = await service.connectToDevice(
      device.id,
      deviceName: device.name,
    );

    setState(() {
      _pairingDeviceId = null;
      _isPairing = false;
    });

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل واتصال ${device.name} بنجاح'),
          backgroundColor: NeuroColors.low,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التسجيل لكن فشل الاتصال بالجهاز'),
          backgroundColor: NeuroColors.warning,
        ),
      );
    }
  }

  void _showDeviceDetails(BleDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Row(
          children: [
            Icon(Icons.bluetooth, color: NeuroColors.primary),
            SizedBox(width: 8),
            Text(device.name, style: NeuroTypography.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('اسم الجهاز', device.name),
            _buildDetailRow('الرقم التسلسلي (BLE ID)', device.id),
            _buildDetailRow('قوة الإشارة', '${device.rssi} dBm'),
            SizedBox(height: NeuroSpacing.md),
            Container(
              padding: EdgeInsets.all(NeuroSpacing.sm),
              decoration: BoxDecoration(
                color: NeuroColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(NeuroRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: NeuroColors.info, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك استخدام هذا الرقم كرقم تسلسلي للجهاز',
                      style: NeuroTypography.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: NeuroColors.navInactive)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pairDevice(device);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeuroColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إزواج الآن'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: NeuroTypography.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: NeuroTypography.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(bleScanStateProvider);
    final devicesAsync = ref.watch(bleDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إزواج جهاز BLE'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(NeuroSpacing.xl),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 80 + _scanAnimation.value * 20,
                      height: 80 + _scanAnimation.value * 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NeuroColors.primary.withValues(
                          alpha: isScanning
                              ? 0.3 - (_scanAnimation.value * 0.2)
                              : 0.1,
                        ),
                        border: Border.all(
                          color: NeuroColors.primary.withValues(
                            alpha: isScanning
                                ? 0.6 - (_scanAnimation.value * 0.4)
                                : 0.3,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isScanning
                              ? Icons.bluetooth_searching
                              : Icons.bluetooth,
                          size: 36,
                          color: NeuroColors.primary,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: NeuroSpacing.md),
                Text(
                  isScanning ? 'جاري البحث عن أجهزة...' : 'اضغط للبحث عن أجهزة BLE',
                  style: NeuroTypography.bodyMedium?.copyWith(
                    color: NeuroColors.textSecondary,
                  ),
                ),
                SizedBox(height: NeuroSpacing.sm),
                Text(
                  'تأكد من أن الجهاز مضاء وقريب منك',
                  style: NeuroTypography.caption,
                ),
                SizedBox(height: NeuroSpacing.md),
                SizedBox(
                  width: 200,
                  height: 44,
                  child: AppButton(
                    label: isScanning ? 'إيقاف البحث' : 'بحث عن أجهزة',
                    icon: isScanning ? Icons.stop : Icons.bluetooth_searching,
                    variant: isScanning
                        ? ButtonVariant.secondary
                        : ButtonVariant.primary,
                    onPressed: isScanning ? _stopScan : _startScan,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(child: _buildDeviceList(context, devicesAsync, isScanning)),
        ],
      ),
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    AsyncValue<List<BleDevice>> devicesAsync,
    bool isScanning,
  ) {
    if (!isScanning && devicesAsync.valueOrNull == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: NeuroColors.navInactive),
            SizedBox(height: NeuroSpacing.md),
            Text(
              'ابدأ البحث للعثور على أجهزة NeuroBleed',
              style: NeuroTypography.bodyMedium?.copyWith(
                color: NeuroColors.textSecondary,
              ),
            ),
            SizedBox(height: NeuroSpacing.sm),
            Text(
              '1. شغّل الجهاز\n2. اضغط "بحث عن أجهزة"\n3. اختر الجهاز من القائمة',
              style: NeuroTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return devicesAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: NeuroSpacing.md),
            Text('جاري البحث...'),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: NeuroColors.critical),
            SizedBox(height: NeuroSpacing.md),
            Text('خطأ في البحث: $e'),
            SizedBox(height: NeuroSpacing.md),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: _startScan,
            ),
          ],
        ),
      ),
      data: (devices) {
        if (devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth_searching, size: 64, color: NeuroColors.navInactive),
                SizedBox(height: NeuroSpacing.md),
                Text(
                  'لم يتم العثور على أجهزة',
                  style: NeuroTypography.bodyMedium?.copyWith(
                    color: NeuroColors.textSecondary,
                  ),
                ),
                SizedBox(height: NeuroSpacing.sm),
                Text(
                  'تأكد من أن الجهاز مضاء وقريب منك',
                  style: NeuroTypography.caption,
                ),
                if (isScanning) ...[
                  SizedBox(height: NeuroSpacing.md),
                  CircularProgressIndicator(strokeWidth: 2),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(NeuroSpacing.md),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            final isPairing = _pairingDeviceId == device.id;

            return Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
              child: AppCard(
                onTap: isPairing ? null : () => _showDeviceDetails(device),
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(NeuroSpacing.sm),
                        decoration: BoxDecoration(
                          color: NeuroColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(NeuroRadius.md),
                        ),
                        child: Icon(Icons.bluetooth, size: 24, color: NeuroColors.primary),
                      ),
                      SizedBox(width: NeuroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: NeuroTypography.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ID: ${device.id}',
                              style: NeuroTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _SignalStrengthIndicator(strength: device.rssi),
                          SizedBox(height: 4),
                          if (isPairing)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(Icons.chevron_right, color: NeuroColors.navInactive),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SignalStrengthIndicator extends StatelessWidget {
  final int strength;

  const _SignalStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    final bars = strength >= -50
        ? 4
        : strength >= -70
            ? 3
            : strength >= -85
                ? 2
                : 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        return Container(
          width: 4,
          height: 4 + (i * 3).toDouble(),
          margin: EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: i < bars
                ? NeuroColors.primary
                : NeuroColors.navInactive.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
