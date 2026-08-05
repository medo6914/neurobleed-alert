import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import '../providers/device_providers.dart';

class DeviceDiagnosticsScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDiagnosticsScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(deviceDiagnosticsProvider(deviceId));
    final deviceAsync = ref.watch(deviceDetailProvider(deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Diagnostics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(deviceDiagnosticsProvider(deviceId));
            },
          ),
        ],
      ),
      body: diagnosticsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: 'Error Loading Diagnostics',
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceDiagnosticsProvider(deviceId)),
        ),
        data: (diag) {
          return deviceAsync.when(
            loading: () => const Center(child: AppLoading()),
            error: (_1, _2) => _buildDiagnosticsContent(context, diag, null),
            data: (device) => _buildDiagnosticsContent(context, diag, device),
          );
        },
      ),
    );
  }

  Widget _buildDiagnosticsContent(
      BuildContext context, DeviceDiagnostics diag, Device? device) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DiagnosticCard(
            title: 'System Health',
            icon: Icons.monitor_heart,
            children: [
              _DiagRow(
                label: 'Device ID',
                value: diag.deviceId,
              ),
              if (diag.status != null)
                _DiagRow(
                  label: 'Status',
                  value: diag.status!,
                  valueColor: diag.status == 'online'
                      ? NeuroColors.success
                      : diag.status == 'error'
                          ? NeuroColors.critical
                          : null,
                ),
              if (diag.lastSeen != null)
                _DiagRow(
                  label: 'Last Seen',
                  value: _formatTimestamp(diag.lastSeen!),
                ),
              if (diag.uptime != null)
                _DiagRow(
                  label: 'Uptime',
                  value: _formatUptime(diag.uptime!),
                ),
            ],
          ),
          SizedBox(height: NeuroSpacing.md),
          _DiagnosticCard(
            title: 'Power',
            icon: Icons.power,
            children: [
              if (diag.batteryLevel != null)
                _DiagRow(
                  label: 'Battery Level',
                  value: '${diag.batteryLevel!.toStringAsFixed(0)}%',
                  valueColor: diag.batteryLevel! < 20
                      ? NeuroColors.critical
                      : diag.batteryLevel! < 50
                          ? NeuroColors.high
                          : NeuroColors.success,
                ),
              if (diag.chargingStatus != null)
                _DiagRow(
                  label: 'Charging',
                  value: diag.chargingStatus! ? 'Yes' : 'No',
                  valueColor: diag.chargingStatus! ? NeuroColors.success : null,
                ),
            ],
          ),
          SizedBox(height: NeuroSpacing.md),
          _DiagnosticCard(
            title: 'Connectivity',
            icon: Icons.wifi,
            children: [
              if (diag.signalStrength != null)
                _DiagRow(
                  label: 'Signal Strength',
                  value: '${diag.signalStrength} dBm',
                ),
              if (diag.lteSignal != null)
                _DiagRow(
                  label: 'LTE Signal',
                  value: '${diag.lteSignal} dBm',
                ),
              if (diag.bleStatus != null)
                _DiagRow(
                  label: 'BLE Status',
                  value: diag.bleStatus!,
                  valueColor: diag.bleStatus == 'connected'
                      ? NeuroColors.success
                      : NeuroColors.critical,
                ),
              if (diag.simStatus != null)
                _DiagRow(
                  label: 'SIM Status',
                  value: diag.simStatus!,
                  valueColor: diag.simStatus == 'active'
                      ? NeuroColors.success
                      : NeuroColors.critical,
                ),
            ],
          ),
          SizedBox(height: NeuroSpacing.md),
          _DiagnosticCard(
            title: 'Hardware',
            icon: Icons.memory,
            children: [
              if (diag.temperature != null)
                _DiagRow(
                  label: 'Temperature',
                  value: '${diag.temperature!.toStringAsFixed(1)}°C',
                  valueColor: diag.temperature! > 50
                      ? NeuroColors.critical
                      : diag.temperature! > 40
                          ? NeuroColors.high
                          : null,
                ),
              if (diag.firmwareVersion != null)
                _DiagRow(
                  label: 'Firmware Version',
                  value: diag.firmwareVersion!,
                ),
              if (diag.hardwareVersion != null)
                _DiagRow(
                  label: 'Hardware Version',
                  value: diag.hardwareVersion!,
                ),
            ],
          ),
          SizedBox(height: NeuroSpacing.xl),
          if (device != null)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'View Health Dashboard',
                icon: Icons.favorite,
                variant: ButtonVariant.secondary,
                onPressed: () {
                  // Navigate to health screen
                },
              ),
            ),
          SizedBox(height: NeuroSpacing.lg),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return dt.toLocal().toString().substring(0, 16);
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m ${secs}s';
    if (hours > 0) return '${hours}h ${minutes}m ${secs}s';
    if (minutes > 0) return '${minutes}m ${secs}s';
    return '${secs}s';
  }
}

class _DiagnosticCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DiagnosticCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                SizedBox(width: NeuroSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DiagRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
