import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'device_status_indicator.dart';
import 'device_battery_indicator.dart';
import 'device_signal_indicator.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  IconData _deviceIcon() {
    switch (device.type) {
      case DeviceType.headband:
        return Icons.headphones;
      case DeviceType.wearable:
        return Icons.watch;
      case DeviceType.bedside:
        return Icons.monitor;
    }
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = device.name ?? device.serialNumber;

    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: AppCard(
        onTap: onTap,
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
                    child: Icon(
                      _deviceIcon(),
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
                          displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SN: ${device.serialNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              SizedBox(height: NeuroSpacing.sm),
              Divider(height: 1),
              SizedBox(height: NeuroSpacing.sm),
              Row(
                children: [
                  DeviceStatusIndicator(status: device.status),
                  SizedBox(width: NeuroSpacing.md),
                  DeviceBatteryIndicator(
                    batteryLevel: device.batteryLevel,
                  ),
                  Spacer(),
                  DeviceSignalIndicator(
                    signalStrength: device.signalStrength.toDouble(),
                  ),
                ],
              ),
              SizedBox(height: NeuroSpacing.xs),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 12, color: theme.colorScheme.onSurfaceVariant),
                  SizedBox(width: 4),
                  Text(
                    'Last seen: ${_relativeTime(device.lastHeartbeat)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
