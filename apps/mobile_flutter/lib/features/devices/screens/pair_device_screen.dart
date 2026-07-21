import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
class _SimulatedDevice {
  final String name;
  final String identifier;
  final int signalStrength;

  const _SimulatedDevice({
    required this.name,
    required this.identifier,
    required this.signalStrength,
  });
}

final _simulatedDevicesProvider = FutureProvider<List<_SimulatedDevice>>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
  return const [
    _SimulatedDevice(name: 'NB-01 Headband', identifier: 'NB-01-0042', signalStrength: -65),
    _SimulatedDevice(name: 'NB-02 Wearable', identifier: 'NB-02-0017', signalStrength: -72),
    _SimulatedDevice(name: 'NB-01 Headband', identifier: 'NB-01-0089', signalStrength: -81),
    _SimulatedDevice(name: 'NB-02 Wearable', identifier: 'NB-02-0033', signalStrength: -58),
    _SimulatedDevice(name: 'Bedside Monitor', identifier: 'BSM-0001', signalStrength: -45),
  ];
});

class PairDeviceScreen extends ConsumerStatefulWidget {
  const PairDeviceScreen({super.key});

  @override
  ConsumerState<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends ConsumerState<PairDeviceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimation;
  bool _isScanning = false;
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

  void _startScan() {
    setState(() => _isScanning = true);
    _scanAnimation.repeat();
    ref.invalidate(_simulatedDevicesProvider);
  }

  void _stopScan() {
    setState(() => _isScanning = false);
    _scanAnimation.stop();
    _scanAnimation.reset();
  }

  Future<void> _pairDevice(String identifier) async {
    setState(() => _pairingDeviceId = identifier);

    await Future.delayed(const Duration(seconds: 3));

    setState(() => _pairingDeviceId = null);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paired with $identifier successfully')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = _isScanning ? ref.watch(_simulatedDevicesProvider) : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
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
                        color: theme.colorScheme.primary.withValues(
                          alpha: _isScanning ? 0.3 - (_scanAnimation.value * 0.2) : 0.1,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: _isScanning ? 0.6 - (_scanAnimation.value * 0.4) : 0.3,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: NeuroSpacing.md),
                Text(
                  _isScanning ? 'Scanning for devices...' : 'Ready to pair',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: NeuroSpacing.sm),
                SizedBox(
                  width: 180,
                  height: 40,
                  child: AppButton(
                    label: _isScanning ? 'Stop Scan' : 'Scan for Devices',
                    icon: _isScanning ? Icons.stop : Icons.search,
                    variant: _isScanning ? ButtonVariant.secondary : ButtonVariant.primary,
                    onPressed: _isScanning ? _stopScan : _startScan,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Expanded(
            child: _buildDeviceList(context, devicesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, AsyncValue<List<_SimulatedDevice>>? devicesAsync) {
    if (!_isScanning) {
      return AppEmptyState(
        icon: Icons.bluetooth_disabled,
        title: 'Not Scanning',
        message: 'Tap "Scan for Devices" to discover nearby NeuroBleed devices.',
      );
    }

    return devicesAsync!.when(
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
            final isPairing = _pairingDeviceId == device.identifier;
            final theme = Theme.of(context);

            return Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
              child: AppCard(
                onTap: isPairing ? null : () => _pairDevice(device.identifier),
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(NeuroSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(NeuroRadius.md),
                        ),
                        child: Icon(
                          Icons.bluetooth,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: NeuroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'ID: ${device.identifier}',
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
                          _SignalStrengthIndicator(strength: device.signalStrength),
                          SizedBox(height: 4),
                          if (isPairing)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
    final bars = strength >= -50 ? 4 : strength >= -70 ? 3 : strength >= -85 ? 2 : 1;
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
