import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../foundations/breakpoints.dart';

class AppAdaptive extends StatelessWidget {
  final Widget Function(BuildContext) mobile;
  final Widget Function(BuildContext)? tablet;
  final Widget Function(BuildContext)? desktop;
  final bool useCupertino;

  const AppAdaptive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.useCupertino = false,
  });

  static bool get _isCupertinoStyle {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    final isCupertino = useCupertino && _isCupertinoStyle;

    Widget buildForFormFactor(BuildContext context) {
      if (Breakpoints.isDesktop(context) && desktop != null) {
        return desktop!(context);
      }
      if (Breakpoints.isTablet(context) && tablet != null) {
        return tablet!(context);
      }
      return mobile(context);
    }

    if (isCupertino) {
      return CupertinoTheme(
        data: CupertinoThemeData(
          brightness: Theme.of(context).brightness,
          primaryColor: Theme.of(context).colorScheme.primary,
          scaffoldBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          textTheme: CupertinoTextThemeData(
            primaryColor: Theme.of(context).colorScheme.primary,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        child: buildForFormFactor(context),
      );
    }

    return buildForFormFactor(context);
  }
}
