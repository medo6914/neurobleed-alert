import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class Range {
  final double min;
  final double max;
  const Range(this.min, this.max);
}

class VitalSignGauge extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Range normalRange;
  final IconData icon;

  const VitalSignGauge({
    super.key,
    required this.label,
    this.value,
    required this.unit,
    required this.normalRange,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value?.toStringAsFixed(value! < 10 ? 1 : 0) ?? '--';

    Color statusColor;
    if (value == null) {
      statusColor = NeuroColors.textSecondary;
    } else if (value! < normalRange.min || value! > normalRange.max) {
      statusColor = NeuroColors.error;
    } else {
      statusColor = NeuroColors.success;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withAlpha(18),
            border: Border.all(color: statusColor.withAlpha(80), width: 2),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayValue,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: value != null && value! >= 100 ? 12 : 14,
                  ),
                ),
                Text(
                  unit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor.withAlpha(180),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
