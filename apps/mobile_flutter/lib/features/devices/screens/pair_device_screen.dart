import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../services/ble_service.dart';

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
    setState(() => _pairingDeviceId = device.id);
    final service = ref.read(bleServiceProvider);
    final success = await service.connectToDevice(device.id);
    setState(() => _pairingDeviceId = null);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paired with ${device.name} successfully')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pairing failed'),
            backgroundColor: NeuroColors.critical),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(bleScanStateProvider);
    final devicesAsync = ref.watch(bleDevicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'Provision Device',
            onPressed: () => context.push('/devices/provision'),
          ),
        ],
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
                        color: theme.colorScheme.primary.withValues(
                          alpha: isScanning
                              ? 0.3 - (_scanAnimation.value * 0.2)
                              : 0.1,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
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
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: NeuroSpacing.md),
                Text(
                  isScanning ? 'Scanning for devices...' : 'Ready to pair',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: NeuroSpacing.sm),
                SizedBox(
                  width: 180,
                  height: 40,
                  child: AppButton(
                    label: isScanning ? 'Stop Scan' : 'Scan for Devices',
                    icon: isScanning ? Icons.stop : Icons.search,
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
          Expanded(
            child: _buildDeviceList(context, devicesAsync, isScanning),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    AsyncValue<List<BleDevice>> devicesAsync,
    bool isScanning,
  ) {
    final theme = Theme.of(context);

    if (!isScanning) {
      return AppEmptyState(
        icon: Icons.bluetooth_disabled,
        title: 'Not Scanning',
        message:
            'Tap "Scan for Devices" to discover nearby NeuroBleed devices.',
      );
    }

    return devicesAsync.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: NeuroSpacing.md),
            Text('Searching for nearby devices...'),
          ],
        ),
      ),
      error: (e, _) => AppErrorState(
        title: 'Scan Error',
        message: e.toString(),
        onRetry: _startScan,
      ),
      data: (devices) {
        if (devices.isEmpty) {
          return AppEmptyState(
            icon: Icons.bluetooth_searching,
            title: 'No Devices Found',
            message: 'Ensure the device is powered on and nearby.',
            actionLabel: 'Scan Again',
            onAction: _startScan,
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
                onTap: isPairing ? null : () => _pairDevice(device),
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(NeuroSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(NeuroRadius.md),
                        ),
                        child: Icon(Icons.bluetooth,
                            size: 24, color: theme.colorScheme.primary),
                      ),
                      SizedBox(width: NeuroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ID: ${device.id}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
                            Icon(Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        return Container(
          width: 4,
          height: 4 + (i * 3).toDouble(),
          margin: EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: i < bars
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
