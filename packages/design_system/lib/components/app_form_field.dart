import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class AppFormField extends StatelessWidget {
  final String label;
  final String? helperText;
  final bool required;
  final Widget child;

  const AppFormField({
    super.key,
    required this.label,
    this.helperText,
    this.required = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: NeuroTypography.textTheme.labelLarge?.copyWith(
                  color: NeuroColors.textPrimary,
                ),
              ),
              if (required) ...[
                const SizedBox(width: NeuroSpacing.xxs),
                Text(
                  '*',
                  style: NeuroTypography.textTheme.labelLarge?.copyWith(
                    color: NeuroColors.error,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: NeuroSpacing.xs),
          child,
          if (helperText != null) ...[
            const SizedBox(height: NeuroSpacing.xxs),
            Text(
              helperText!,
              style: NeuroTypography.textTheme.bodySmall?.copyWith(
                color: NeuroColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
