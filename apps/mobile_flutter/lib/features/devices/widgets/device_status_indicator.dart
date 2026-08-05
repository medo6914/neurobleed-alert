import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
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
        return NeuroColors.success;
      case DeviceStatus.offline:
        return NeuroColors.textSecondary;
      case DeviceStatus.pairing:
        return NeuroColors.info;
      case DeviceStatus.error:
        return NeuroColors.critical;
      case DeviceStatus.lowBattery:
        return NeuroColors.high;
      case DeviceStatus.maintenance:
        return NeuroColors.medium;
    }
  }

  String _statusLabel() {
    switch (status) {
      case DeviceStatus.online:
        return 'متصل';
      case DeviceStatus.offline:
        return 'غير متصل';
      case DeviceStatus.pairing:
        return 'اقتران';
      case DeviceStatus.error:
        return 'خطأ';
      case DeviceStatus.lowBattery:
        return 'بطارية منخفضة';
      case DeviceStatus.maintenance:
        return 'صيانة';
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
