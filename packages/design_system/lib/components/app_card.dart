import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.backgroundColor,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final card = Container(
      padding: padding ?? const EdgeInsets.all(NeuroSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? NeuroColors.surfaceDark : NeuroColors.surface),
        borderRadius: borderRadius ?? BorderRadius.circular(NeuroRadius.lg),
        boxShadow: [
          elevation != null
              ? NeuroShadows.elevated
              : NeuroShadows.card,
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(NeuroRadius.lg),
          child: card,
        ),
      );
    }

    return card;
  }
}
