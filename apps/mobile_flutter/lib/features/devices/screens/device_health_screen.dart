import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import '../providers/device_providers.dart';
import '../widgets/device_widgets.dart';

class DeviceHealthScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceHealthScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceHealthScreen> createState() => _DeviceHealthScreenState();
}

class _DeviceHealthScreenState extends ConsumerState<DeviceHealthScreen> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(deviceDetailProvider(widget.deviceId));
      ref.invalidate(deviceDiagnosticsProvider(widget.deviceId));
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceDetailProvider(widget.deviceId));
    final diagnosticsAsync = ref.watch(deviceDiagnosticsProvider(widget.deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Health'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(deviceDetailProvider(widget.deviceId));
              ref.invalidate(deviceDiagnosticsProvider(widget.deviceId));
            },
          ),
        ],
      ),
      body: deviceAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: 'Error',
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(widget.deviceId)),
        ),
        data: (device) {
          return diagnosticsAsync.when(
            loading: () => const Center(child: AppLoading()),
            error: (e, _) => _buildHealthContent(context, device, null),
            data: (diag) => _buildHealthContent(context, device, diag),
          );
        },
      ),
    );
  }

  Widget _buildHealthContent(BuildContext context, Device device, DeviceDiagnostics? diag) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: device.status == DeviceStatus.online
                        ? NeuroColors.success.withValues(alpha: 0.1)
                        : device.status == DeviceStatus.error
                            ? NeuroColors.critical.withValues(alpha: 0.1)
                            : NeuroColors.textSecondary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: device.status == DeviceStatus.online
                          ? NeuroColors.success
                          : device.status == DeviceStatus.error
                              ? NeuroColors.critical
                              : NeuroColors.textSecondary,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          device.status == DeviceStatus.online
                              ? Icons.check_circle
                              : device.status == DeviceStatus.error
                                  ? Icons.error
                                  : Icons.circle,
                          size: 36,
                          color: device.status == DeviceStatus.online
                              ? NeuroColors.success
                              : device.status == DeviceStatus.error
                                  ? NeuroColors.critical
                                  : NeuroColors.textSecondary,
                        ),
                        SizedBox(height: 4),
                        Text(
                          device.status.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: device.status == DeviceStatus.online
                                ? NeuroColors.success
                                : device.status == DeviceStatus.error
                                    ? NeuroColors.critical
                                    : NeuroColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: NeuroSpacing.md),
                Text(
                  device.name ?? device.serialNumber,
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: 4),
                Text(
                  'SN: ${device.serialNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.xl),

          Row(
            children: [
              Expanded(
                child: _HealthMetricCard(
                  icon: Icons.battery_full,
                  label: 'Battery',
                  value: '${device.batteryLevel.toStringAsFixed(0)}%',
                  color: device.batteryLevel < 20
                      ? NeuroColors.critical
                      : device.batteryLevel < 50
                          ? NeuroColors.high
                          : NeuroColors.success,
                  subtitle: diag?.chargingStatus == true ? 'Charging' : null,
                ),
              ),
              SizedBox(width: NeuroSpacing.sm),
              Expanded(
                child: _HealthMetricCard(
                  icon: Icons.signal_cellular_alt,
                  label: 'Signal',
                  value: '${device.signalStrength} dBm',
                  color: device.signalStrength >= -70
                      ? NeuroColors.success
                      : device.signalStrength >= -85
                          ? NeuroColors.high
                          : NeuroColors.critical,
                ),
              ),
            ],
          ),
          SizedBox(height: NeuroSpacing.sm),
          Row(
            children: [
              if (diag?.temperature != null)
                Expanded(
                  child: _HealthMetricCard(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: '${diag!.temperature!.toStringAsFixed(1)}°C',
                    color: diag.temperature! > 45
                        ? NeuroColors.critical
                        : NeuroColors.success,
                  ),
                ),
              if (diag?.uptime != null)
                Expanded(
                  child: _HealthMetricCard(
                    icon: Icons.timer,
                    label: 'Uptime',
                    value: _formatUptime(diag!.uptime!),
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          SizedBox(height: NeuroSpacing.lg),

          AppCard(
            child: Padding(
              padding: EdgeInsets.all(NeuroSpacing.md),
              child: Column(
                children: [
                  DeviceMetricTile(
                    icon: Icons.access_time,
                    label: 'Last Heartbeat',
                    value: _relativeTime(device.lastHeartbeat),
                    valueColor: DateTime.now().difference(device.lastHeartbeat).inMinutes > 5
                        ? NeuroColors.critical
                        : null,
                  ),
                  if (device.lastReadingAt != null)
                    DeviceMetricTile(
                      icon: Icons.trending_up,
                      label: 'Last Reading',
                      value: _relativeTime(device.lastReadingAt!),
                    ),
                  if (diag?.firmwareVersion != null)
                    DeviceMetricTile(
                      icon: Icons.memory,
                      label: 'Firmware',
                      value: diag!.firmwareVersion!,
                    ),
                  if (diag?.bleStatus != null)
                    DeviceMetricTile(
                      icon: Icons.bluetooth,
                      label: 'BLE',
                      value: diag!.bleStatus!,
                    ),
                  if (diag?.lteSignal != null)
                    DeviceMetricTile(
                      icon: Icons.signal_cellular_alt,
                      label: 'LTE Signal',
                      value: '${diag!.lteSignal} dBm',
                    ),
                  if (diag?.simStatus != null)
                    DeviceMetricTile(
                      icon: Icons.sim_card,
                      label: 'SIM',
                      value: diag!.simStatus!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _HealthMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _HealthMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(NeuroSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: NeuroSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
