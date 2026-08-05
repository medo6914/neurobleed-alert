import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../models/ble_test_models.dart';
import '../providers/ble_test_providers.dart';

class BleTestDeviceCard extends ConsumerWidget {
  final BleTestDevice device;
  final bool isConnecting;
  final VoidCallback? onConnect;

  const BleTestDeviceCard({
    super.key,
    required this.device,
    this.isConnecting = false,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bars = device.rssi >= -50
        ? 4
        : device.rssi >= -70
            ? 3
            : device.rssi >= -85
                ? 2
                : 1;

    return AppCard(
      onTap: isConnecting ? null : onConnect,
      child: Padding(
        padding: EdgeInsets.all(NeuroSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(NeuroSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(NeuroRadius.md),
                  ),
                  child: Icon(Icons.bluetooth,
                      size: 22, color: theme.colorScheme.primary),
                ),
                SizedBox(width: NeuroSpacing.sm),
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
                        device.id,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (i) {
                    return Container(
                      width: 5,
                      height: 5 + (i * 3).toDouble(),
                      margin: EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: i < bars
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
                SizedBox(width: NeuroSpacing.sm),
                Text('${device.rssi} dBm', style: theme.textTheme.labelSmall),
              ],
            ),
            if (device.advertisementData.isNotEmpty) ...[
              SizedBox(height: NeuroSpacing.sm),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: device.advertisementData.entries.map((e) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 9,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (onConnect != null) ...[
              SizedBox(height: NeuroSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: isConnecting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppButton(
                        label: 'Connect',
                        icon: Icons.link,
                        variant: ButtonVariant.secondary,
                        onPressed: onConnect,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ServiceExplorer extends ConsumerWidget {
  const ServiceExplorer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(bleTestServicesProvider);
    final theme = Theme.of(context);

    return servicesAsync.when(
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.all(NeuroSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: NeuroSpacing.md),
              Text('Discovering services...', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
      error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
      data: (services) {
        if (services.isEmpty) {
          return Center(
              child: Text('No services discovered',
                  style: theme.textTheme.bodySmall));
        }

        return ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
              child: ExpansionTile(
                initiallyExpanded: index < 2,
                title: Text(
                  'Service 0x${service.uuid.toUpperCase()}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${service.characteristics.length} characteristic(s)',
                  style: theme.textTheme.labelSmall,
                ),
                children: service.characteristics.map((ch) {
                  return Padding(
                    padding: EdgeInsets.only(left: NeuroSpacing.lg, bottom: 4),
                    child: AppCard(
                      child: Padding(
                        padding: EdgeInsets.all(NeuroSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '0x${ch.uuid.toUpperCase()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                if (ch.isReadable)
                                  _PropertyChip(
                                      label: 'Read',
                                      color: NeuroColors.chartBlue),
                                if (ch.isWritable)
                                  _PropertyChip(
                                      label: 'Write', color: NeuroColors.low),
                                if (ch.isNotifiable)
                                  _PropertyChip(
                                      label: 'Notify',
                                      color: NeuroColors.medium),
                                if (ch.isIndicatable)
                                  _PropertyChip(
                                      label: 'Indicate',
                                      color: NeuroColors.temperature),
                              ],
                            ),
                            if (ch.value != null && ch.value!.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                'Value: ${ch.value!.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _PropertyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PropertyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class BleTestLogViewer extends ConsumerWidget {
  const BleTestLogViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(bleTestLogsProvider);
    final theme = Theme.of(context);

    return logsAsync.when(
      loading: () => Center(
          child: Text('Loading logs...', style: theme.textTheme.bodySmall)),
      error: (e, _) => AppErrorState(title: 'Log Error', message: e.toString()),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4)),
                SizedBox(height: NeuroSpacing.sm),
                Text('No operations logged yet',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final entry = logs[index];
            final ts = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                '${entry.timestamp.second.toString().padLeft(2, '0')}';
            final color = switch (entry.level) {
              LogLevel.error => NeuroColors.critical,
              LogLevel.warning => NeuroColors.medium,
              LogLevel.success => NeuroColors.low,
              LogLevel.info => theme.colorScheme.onSurfaceVariant,
            };

            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: NeuroSpacing.sm, vertical: 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ts,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      )),
                  SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entry.message,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ConnectionPanel extends ConsumerWidget {
  const ConnectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(bleTestConnectedDeviceInfoProvider);
    final theme = Theme.of(context);

    final stateColor = switch (info.state) {
      BleTestConnectionState.disconnected => NeuroColors.textSecondary,
      BleTestConnectionState.connecting => NeuroColors.medium,
      BleTestConnectionState.connected => NeuroColors.low,
      BleTestConnectionState.disconnecting => NeuroColors.high,
    };

    final stateLabel = switch (info.state) {
      BleTestConnectionState.disconnected => 'Disconnected',
      BleTestConnectionState.connecting => 'Connecting...',
      BleTestConnectionState.connected => 'Connected',
      BleTestConnectionState.disconnecting => 'Disconnecting...',
    };

    if (info.state == BleTestConnectionState.disconnected) {
      return AppEmptyState(
        icon: Icons.bluetooth_disabled,
        title: 'Not Connected',
        message: 'Scan and select a device to connect.',
      );
    }

    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(NeuroSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stateColor,
                    boxShadow: info.state == BleTestConnectionState.connected
                        ? [
                            BoxShadow(
                                color: stateColor.withValues(alpha: 0.5),
                                blurRadius: 8)
                          ]
                        : null,
                  ),
                ),
                SizedBox(width: NeuroSpacing.sm),
                Text(stateLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: stateColor,
                    )),
              ],
            ),
            if (info.name != null) ...[
              SizedBox(height: NeuroSpacing.sm),
              _InfoRow(label: 'Name', value: info.name!, theme: theme),
            ],
            if (info.id != null) ...[
              _InfoRow(label: 'MAC', value: info.id!, theme: theme, mono: true),
            ],
            if (info.rssi != null) ...[
              _InfoRow(label: 'RSSI', value: '${info.rssi} dBm', theme: theme),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool mono;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationViewer extends ConsumerWidget {
  const NotificationViewer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(bleTestNotificationProvider);
    final theme = Theme.of(context);

    return notificationAsync.when(
      loading: () => Center(
        child: Text('Waiting for notifications...',
            style: theme.textTheme.bodySmall),
      ),
      error: (e, _) => AppEmptyState(
          icon: Icons.error_outline, title: 'Error', message: e.toString()),
      data: (notification) {
        return AppCard(
          child: Padding(
            padding: EdgeInsets.all(NeuroSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0x${notification.characteristicUuid.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  notification.data
                      .map((b) => b.toRadixString(16).padLeft(2, '0'))
                      .join(' '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
