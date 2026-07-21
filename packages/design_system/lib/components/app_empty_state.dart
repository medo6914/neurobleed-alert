import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Empty state: $title',
        child: Padding(
          padding: const EdgeInsets.all(NeuroSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 64,
                  color: NeuroColors.textSecondary,
                ),
                const SizedBox(height: NeuroSpacing.lg),
              ],
              Text(
                title,
                style: NeuroTypography.textTheme.titleLarge?.copyWith(
                  color: NeuroColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NeuroSpacing.sm),
              Text(
                message,
                style: NeuroTypography.textTheme.bodyMedium?.copyWith(
                  color: NeuroColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: NeuroSpacing.xl),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: ButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
