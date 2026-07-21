import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum AlertSeverity { critical, warning, stable, info }

class AlertBanner extends StatelessWidget {
  final AlertSeverity severity;
  final String title;
  final String? description;
  final VoidCallback? onTap;

  const AlertBanner({
    super.key,
    required this.severity,
    required this.title,
    this.description,
    this.onTap,
  });

  Color get _color {
    switch (severity) {
      case AlertSeverity.critical:
        return NeuroColors.critical;
      case AlertSeverity.warning:
        return NeuroColors.warning;
      case AlertSeverity.stable:
        return NeuroColors.stable;
      case AlertSeverity.info:
        return NeuroColors.info;
    }
  }

  IconData get _icon {
    switch (severity) {
      case AlertSeverity.critical:
        return Icons.warning_rounded;
      case AlertSeverity.warning:
        return Icons.info_rounded;
      case AlertSeverity.stable:
        return Icons.check_circle_rounded;
      case AlertSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = NeuroTypography.textTheme;
    final card = Container(
      padding: const EdgeInsets.all(NeuroSpacing.md),
      decoration: BoxDecoration(
        color: _color.withAlpha(15),
        borderRadius: BorderRadius.circular(NeuroRadius.md),
        border: Border.all(color: _color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 24),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: theme.labelLarge?.copyWith(color: _color)),
                if (description != null) ...[
                  const SizedBox(height: NeuroSpacing.xxs),
                  Text(description!,
                      style: theme.bodySmall?.copyWith(color: _color)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          child: card,
        ),
      );
    }

    return card;
  }
}
