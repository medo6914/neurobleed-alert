import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import '../providers/device_providers.dart';
import '../widgets/device_widgets.dart';
import 'device_diagnostics_screen.dart';

class DeviceDetailScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceDetailProvider(deviceId));

    return deviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Device')),
        body: const Center(child: AppLoading()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Device')),
        body: AppErrorState(
          title: 'Error Loading Device',
          message: error.toString(),
          onRetry: () => ref.invalidate(deviceDetailProvider(deviceId)),
        ),
      ),
      data: (device) => _DeviceDetailContent(device: device),
    );
  }
}

class _DeviceDetailContent extends ConsumerStatefulWidget {
  final Device device;
  const _DeviceDetailContent({required this.device});

  @override
  ConsumerState<_DeviceDetailContent> createState() =>
      _DeviceDetailContentState();
}

class _DeviceDetailContentState extends ConsumerState<_DeviceDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final displayName = device.name ?? device.serialNumber;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/devices/${device.id}/edit'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Assignment'),
            Tab(text: 'Diagnostics'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(device: device),
          _AssignmentTab(device: device),
          _DiagnosticsTab(deviceId: device.id),
          _HistoryTab(deviceId: device.id),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Device device;
  const _OverviewTab({required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      device.type == DeviceType.headband
                          ? Icons.headphones
                          : device.type == DeviceType.wearable
                              ? Icons.watch
                              : Icons.monitor,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(device.name ?? device.serialNumber),
                  subtitle: Text('SN: ${device.serialNumber}'),
                  trailing: DeviceStatusIndicator(status: device.status),
                ),
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    children: [
                      DeviceMetricTile(
                        icon: Icons.smartphone,
                        label: 'Device Type',
                        value: device.type.name,
                      ),
                      DeviceMetricTile(
                        icon: Icons.memory,
                        label: 'Firmware',
                        value: device.firmwareVersion,
                      ),
                      if (device.hardwareVersion != null)
                        DeviceMetricTile(
                          icon: Icons.settings,
                          label: 'Hardware',
                          value: device.hardwareVersion!,
                        ),
                      DeviceMetricTile(
                        icon: Icons.access_time,
                        label: 'Last Heartbeat',
                        value: device.lastHeartbeat
                            .toLocal()
                            .toString()
                            .substring(0, 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          _ConnectionActions(device: device),
          SizedBox(height: NeuroSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      DeviceBatteryIndicator(batteryLevel: device.batteryLevel),
                      SizedBox(height: NeuroSpacing.xs),
                      Text(
                        'Battery',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: NeuroSpacing.sm),
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      DeviceSignalIndicator(
                        signalStrength: device.signalStrength.toDouble(),
                      ),
                      SizedBox(height: NeuroSpacing.xs),
                      Text(
                        'Signal',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: NeuroSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      left: NeuroSpacing.md, top: NeuroSpacing.md),
                  child: Text(
                    'Additional Info',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    children: [
                      DeviceMetricTile(
                        icon: Icons.fingerprint,
                        label: 'Serial Number',
                        value: device.serialNumber,
                      ),
                      DeviceMetricTile(
                        icon: Icons.calendar_today,
                        label: 'Registered',
                        value: device.createdAt
                            .toLocal()
                            .toString()
                            .substring(0, 10),
                      ),
                      if (device.pairedAt != null)
                        DeviceMetricTile(
                          icon: Icons.link,
                          label: 'Paired',
                          value: device.pairedAt!
                              .toLocal()
                              .toString()
                              .substring(0, 10),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTab extends ConsumerWidget {
  final Device device;
  const _AssignmentTab({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.assignment, color: theme.colorScheme.primary),
                      SizedBox(width: NeuroSpacing.sm),
                      Text(
                        'Assignment Details',
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
                    children: [
                      DeviceMetricTile(
                        icon: Icons.person,
                        label: 'Assigned Patient',
                        value: device.patientId != null
                            ? device.patientId!
                            : 'Not assigned',
                        valueColor: device.patientId != null
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      if (device.patientId != null) ...[
                        SizedBox(height: NeuroSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'View Patient',
                            variant: ButtonVariant.secondary,
                            onPressed: () =>
                                context.push('/patients/${device.patientId}'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: NeuroSpacing.md),
          AppCard(
            child: Padding(
              padding: EdgeInsets.all(NeuroSpacing.md),
              child: Column(
                children: [
                  DeviceMetricTile(
                    icon: Icons.local_hospital,
                    label: 'Hospital',
                    value: device.hospitalId ?? 'Not assigned',
                    valueColor: device.hospitalId != null
                        ? null
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (device.hospitalId != null)
                    DeviceMetricTile(
                      icon: Icons.business,
                      label: 'Hospital ID',
                      value: device.hospitalId!,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: NeuroSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: device.patientId != null
                  ? 'Unassign Device'
                  : 'Assign Device',
              icon: device.patientId != null ? Icons.link_off : Icons.link,
              variant: device.patientId != null
                  ? ButtonVariant.danger
                  : ButtonVariant.primary,
              onPressed: () {
                if (device.patientId != null) {
                  _confirmUnassign(context, ref);
                } else {
                  context.push('/devices/${device.id}/assign');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmUnassign(BuildContext context, WidgetRef ref) {
    AppDialog.confirm(
      context,
      title: 'Unassign Device',
      message: 'Are you sure you want to unassign this device?',
      confirmLabel: 'Unassign',
      isDangerous: true,
    ).then((confirmed) {
      if (confirmed == true) {
        ref
            .read(deviceAssignProvider.notifier)
            .unassignDevice(device.id)
            .then((result) {
          result.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(failure.message),
                    backgroundColor: NeuroColors.critical),
              );
            },
            (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device unassigned successfully')),
              );
              ref.invalidate(deviceDetailProvider(device.id));
            },
          );
        });
      }
    });
  }
}

class _DiagnosticsTab extends ConsumerWidget {
  final String deviceId;
  const _DiagnosticsTab({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticsAsync = ref.watch(deviceDiagnosticsProvider(deviceId));

    return diagnosticsAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (e, _) => AppErrorState(
        title: 'Error Loading Diagnostics',
        message: e.toString(),
        onRetry: () => ref.invalidate(deviceDiagnosticsProvider(deviceId)),
      ),
      data: (diag) {
        if (diag.deviceId.isEmpty) {
          return AppEmptyState(
            icon: Icons.monitor_heart,
            title: 'No Diagnostics',
            message: 'Diagnostic data not available for this device.',
          );
        }

        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(NeuroSpacing.md),
                      child: Text(
                        'Device Health',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(NeuroSpacing.md),
                      child: Column(
                        children: [
                          if (diag.batteryLevel != null)
                            DeviceMetricTile(
                              icon: Icons.battery_full,
                              label: 'Battery Level',
                              value:
                                  '${diag.batteryLevel!.toStringAsFixed(0)}%',
                              valueColor: diag.batteryLevel! < 20
                                  ? NeuroColors.critical
                                  : null,
                            ),
                          if (diag.signalStrength != null)
                            DeviceMetricTile(
                              icon: Icons.network_cell,
                              label: 'Signal Strength',
                              value: '${diag.signalStrength} dBm',
                            ),
                          if (diag.temperature != null)
                            DeviceMetricTile(
                              icon: Icons.thermostat,
                              label: 'Temperature',
                              value:
                                  '${diag.temperature!.toStringAsFixed(1)}°C',
                            ),
                          if (diag.uptime != null)
                            DeviceMetricTile(
                              icon: Icons.timer,
                              label: 'Uptime',
                              value: _formatUptime(diag.uptime!),
                            ),
                          if (diag.chargingStatus != null)
                            DeviceMetricTile(
                              icon: diag.chargingStatus!
                                  ? Icons.bolt
                                  : Icons.battery_std,
                              label: 'Charging',
                              value: diag.chargingStatus! ? 'Yes' : 'No',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: NeuroSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(NeuroSpacing.md),
                      child: Text(
                        'Connectivity',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(NeuroSpacing.md),
                      child: Column(
                        children: [
                          if (diag.lteSignal != null)
                            DeviceMetricTile(
                              icon: Icons.signal_cellular_alt,
                              label: 'LTE Signal',
                              value: '${diag.lteSignal} dBm',
                            ),
                          if (diag.bleStatus != null)
                            DeviceMetricTile(
                              icon: Icons.bluetooth,
                              label: 'BLE Status',
                              value: diag.bleStatus!,
                            ),
                          if (diag.simStatus != null)
                            DeviceMetricTile(
                              icon: Icons.sim_card,
                              label: 'SIM Status',
                              value: diag.simStatus!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: NeuroSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(NeuroSpacing.md),
                      child: Text(
                        'Version Info',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(NeuroSpacing.md),
                      child: Column(
                        children: [
                          if (diag.firmwareVersion != null)
                            DeviceMetricTile(
                              icon: Icons.memory,
                              label: 'Firmware',
                              value: diag.firmwareVersion!,
                            ),
                          if (diag.hardwareVersion != null)
                            DeviceMetricTile(
                              icon: Icons.settings,
                              label: 'Hardware',
                              value: diag.hardwareVersion!,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: NeuroSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Full Diagnostics',
                  icon: Icons.monitor_heart,
                  variant: ButtonVariant.secondary,
                  onPressed: () =>
                      context.push('/devices/$deviceId/diagnostics'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _HistoryTab extends ConsumerWidget {
  final String deviceId;
  const _HistoryTab({required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(deviceHistoryProvider(deviceId));

    return historyAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (e, _) => AppErrorState(
        title: 'Error Loading History',
        message: e.toString(),
        onRetry: () => ref.invalidate(deviceHistoryProvider(deviceId)),
      ),
      data: (history) {
        if (history.isEmpty) {
          return AppEmptyState(
            icon: Icons.history,
            title: 'No History',
            message: 'No events recorded for this device.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(NeuroSpacing.md),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final event = history[index] as Map<String, dynamic>;
            return _HistoryTile(event: event);
          },
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _HistoryTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = event['event_type'] as String? ?? 'unknown';
    final timestamp = event['timestamp'] as String? ?? '';
    final details =
        event['details'] as String? ?? event['message'] as String? ?? '';

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'heartbeat':
        icon = Icons.favorite;
        iconColor = NeuroColors.success;
      case 'status_change':
        icon = Icons.swap_horiz;
        iconColor = NeuroColors.info;
      case 'fw_update':
      case 'firmware_update':
        icon = Icons.system_update;
        iconColor = NeuroColors.high;
      case 'assignment':
        icon = Icons.link;
        iconColor = NeuroColors.temperature;
      case 'error':
        icon = Icons.error;
        iconColor = NeuroColors.critical;
      default:
        icon = Icons.circle;
        iconColor = theme.colorScheme.onSurfaceVariant;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(NeuroSpacing.xs),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: AppCard(
              child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.replaceAll('_', ' ').toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(details, style: theme.textTheme.bodySmall),
                    ],
                    SizedBox(height: 2),
                    Text(
                      timestamp.isNotEmpty ? timestamp.substring(0, 16) : '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Connect / Disconnect Actions ────────────────────────────────────
class _ConnectionActions extends ConsumerStatefulWidget {
  final Device device;

  const _ConnectionActions({required this.device});

  @override
  ConsumerState<_ConnectionActions> createState() => _ConnectionActionsState();
}

class _ConnectionActionsState extends ConsumerState<_ConnectionActions> {
  bool _busy = false;

  Future<void> _setStatus(DeviceStatus status) async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch(
        '/v1/devices/${widget.device.id}/status',
        data: {
          'status': status.name,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == DeviceStatus.online
                  ? 'تم توصيل الجهاز بنجاح'
                  : 'تم فصل الجهاز',
            ),
          ),
        );
        ref.invalidate(deviceDetailProvider(widget.device.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحديث حالة الجهاز: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final isOnline = device.status == DeviceStatus.online;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(NeuroSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connectivity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: NeuroSpacing.sm),
            Row(
              children: [
                if (isOnline)
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.link_off, size: 18),
                      label: Text(_busy ? 'Disconnecting...' : 'Disconnect'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed:
                          _busy ? null : () => _setStatus(DeviceStatus.offline),
                    ),
                  )
                else
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(_busy ? 'Connecting...' : 'Connect'),
                      onPressed:
                          _busy ? null : () => _setStatus(DeviceStatus.online),
                    ),
                  ),
                const SizedBox(width: NeuroSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.medical_services_outlined, size: 18),
                    label: const Text('Diagnostics'),
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DeviceDiagnosticsScreen(
                                    deviceId: device.id),
                              ),
                            ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NeuroSpacing.sm),
            DeviceMetricTile(
              icon: Icons.history_toggle_off,
              label: 'Last Connected',
              value: device.lastHeartbeat.toLocal().toString().substring(0, 16),
            ),
          ],
        ),
      ),
    );
  }
}
