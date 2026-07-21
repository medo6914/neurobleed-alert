import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class DeviceStatusIndicator extends StatelessWidget {
  final DeviceStatus status;
  final double dotSize;

  const DeviceStatusIndicator({
    super.key,
    required this.status,
    this.dotSize = 8,
  });

  Color _statusColor() {
    switch (status) {
      case DeviceStatus.online:
        return const Color(0xFF4CAF50);
      case DeviceStatus.offline:
        return Colors.grey;
      case DeviceStatus.pairing:
        return const Color(0xFF2196F3);
      case DeviceStatus.error:
        return const Color(0xFFE53935);
      case DeviceStatus.lowBattery:
        return const Color(0xFFF57C00);
      case DeviceStatus.maintenance:
        return const Color(0xFFFFC107);
    }
  }

  String _statusLabel() {
    switch (status) {
      case DeviceStatus.online:
        return 'Online';
      case DeviceStatus.offline:
        return 'Offline';
      case DeviceStatus.pairing:
        return 'Pairing';
      case DeviceStatus.error:
        return 'Error';
      case DeviceStatus.lowBattery:
        return 'Low Battery';
      case DeviceStatus.maintenance:
        return 'Maintenance';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: status == DeviceStatus.online
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(width: 4),
        Text(
          _statusLabel(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
