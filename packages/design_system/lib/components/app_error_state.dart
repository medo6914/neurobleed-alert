import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool isNetworkError;

  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.isNetworkError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Error state: $title',
        child: Padding(
          padding: const EdgeInsets.all(NeuroSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNetworkError
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 64,
                color: NeuroColors.error,
              ),
              const SizedBox(height: NeuroSpacing.lg),
              Text(
                title,
                style: NeuroTypography.textTheme.titleLarge?.copyWith(
                  color: NeuroColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NeuroSpacing.sm),
              Text(
                isNetworkError
                    ? 'Please check your internet connection and try again.'
                    : message,
                style: NeuroTypography.textTheme.bodyMedium?.copyWith(
                  color: NeuroColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: NeuroSpacing.xl),
                AppButton(
                  label: 'Retry',
                  onPressed: onRetry,
                  variant: ButtonVariant.primary,
                  icon: Icons.refresh,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
