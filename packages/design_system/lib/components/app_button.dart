import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum ButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NeuroTypography.textTheme;

    switch (variant) {
      case ButtonVariant.primary:
        return _buildElevatedButton(context, theme);
      case ButtonVariant.secondary:
        return _buildOutlinedButton(context, theme);
      case ButtonVariant.danger:
        return _buildDangerButton(context, theme);
      case ButtonVariant.ghost:
        return _buildTextButton(context, theme);
    }
  }

  Widget _buildElevatedButton(BuildContext context, TextTheme theme) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: NeuroColors.primary,
          foregroundColor: NeuroColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
          ),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, TextTheme theme) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: NeuroColors.primary,
          side: const BorderSide(color: NeuroColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
          ),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildDangerButton(BuildContext context, TextTheme theme) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: NeuroColors.critical,
          foregroundColor: NeuroColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
          ),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, TextTheme theme) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: NeuroColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
          ),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(TextTheme theme) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: NeuroColors.textOnPrimary,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: NeuroSpacing.sm),
        ],
        Text(label, style: theme.labelLarge),
      ],
    );
  }
}
