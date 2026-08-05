import 'package:flutter/material.dart';
import '../foundations/breakpoints.dart';
import '../tokens/app_spacing.dart';

class AppResponsive extends StatelessWidget {
  final Widget Function(BuildContext) mobile;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;

  const AppResponsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context) && desktop != null) {
      return desktop!(context);
    }
    if (Breakpoints.isTablet(context) && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }

  static double adaptiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (Breakpoints.isDesktop(context) && desktop != null) return desktop;
    if (Breakpoints.isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  static EdgeInsets adaptivePadding(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return const EdgeInsets.all(NeuroSpacing.xxl);
    }
    if (Breakpoints.isTablet(context)) {
      return const EdgeInsets.all(NeuroSpacing.xl);
    }
    return const EdgeInsets.all(NeuroSpacing.lg);
  }

  static int gridColumnCount(BuildContext context) {
    if (Breakpoints.isDesktop(context)) return 4;
    if (Breakpoints.isTablet(context)) return 3;
    return 2;
  }

  static double maxContentWidth(BuildContext context) {
    if (Breakpoints.isDesktop(context)) return 1200;
    if (Breakpoints.isTablet(context)) return 800;
    return double.infinity;
  }

  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Center(
      child: SizedBox(
        width: maxContentWidth(context),
        child: Padding(
          padding: padding ?? adaptivePadding(context),
          child: child,
        ),
      ),
    );
  }
}
