import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../alerts/widgets/alert_overlay.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex(String location) {
    if (location.startsWith('/patients')) return 1;
    if (location.startsWith('/monitoring')) return 2;
    if (location.startsWith('/alerts')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(int index, String location) {
    switch (index) {
      case 0:
        if (location != '/dashboard') context.go('/dashboard');
        break;
      case 1:
        context.go('/patients');
        break;
      case 2:
        context.go('/monitoring');
        break;
      case 3:
        context.go('/alerts');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return AlertOverlay(
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTap(index, location),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: AppLocalizations.of(context).translate(L10n.dashboard) ?? 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_rounded),
              label: AppLocalizations.of(context).translate(L10n.patients) ?? 'Patients',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.monitor_heart_rounded),
              label: AppLocalizations.of(context).translate(L10n.monitoring) ?? 'Monitoring',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_rounded),
              label: AppLocalizations.of(context).translate(L10n.alerts) ?? 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: AppLocalizations.of(context).translate(L10n.settings) ?? 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
