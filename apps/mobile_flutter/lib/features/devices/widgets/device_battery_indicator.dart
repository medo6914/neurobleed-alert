import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class DeviceBatteryIndicator extends StatelessWidget {
  final double batteryLevel;
  final bool? isCharging;

  const DeviceBatteryIndicator({
    super.key,
    required this.batteryLevel,
    this.isCharging,
  });

  Color _batteryColor() {
    if (batteryLevel < 20) return NeuroColors.critical;
    if (batteryLevel < 50) return NeuroColors.high;
    return NeuroColors.success;
  }

  IconData _batteryIcon() {
    if (isCharging == true) return Icons.battery_charging_full;
    if (batteryLevel < 15) return Icons.battery_alert;
    if (batteryLevel < 30) return Icons.battery_1_bar;
    if (batteryLevel < 50) return Icons.battery_2_bar;
    if (batteryLevel < 80) return Icons.battery_3_bar;
    return Icons.battery_full;
  }

  @override
  Widget build(BuildContext context) {
    final color = _batteryColor();
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _batteryIcon(),
          size: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(
          '${batteryLevel.toStringAsFixed(0)}%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: batteryLevel < 20 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
