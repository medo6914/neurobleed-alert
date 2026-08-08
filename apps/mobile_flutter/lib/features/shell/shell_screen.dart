import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
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
    if (location.startsWith('/devices')) return 1;
    if (location.startsWith('/reports') || location.startsWith('/monitoring')) {
      return 2;
    }
    if (location.startsWith('/settings') || location.startsWith('/admin')) {
      return 3;
    }
    return 0;
  }

  void _onTap(int index, String location) {
    switch (index) {
      case 0:
        if (location != '/dashboard') context.go('/dashboard');
        break;
      case 1:
        context.go('/devices');
        break;
      case 2:
        context.go('/reports');
        break;
      case 3:
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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: NeuroColors.navBg,
            border: Border(
              top: BorderSide(
                color: NeuroColors.bgPrimary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) => _onTap(index, location),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: NeuroColors.navActive,
                unselectedItemColor: NeuroColors.navInactive,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: 'الرئيسية',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.devices_outlined),
                    activeIcon: const Icon(Icons.devices),
                    label: 'الأجهزة',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.insert_chart_outlined),
                    activeIcon: const Icon(Icons.insert_chart),
                    label: 'السجل',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person),
                    label: 'الملف الشخصي',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
