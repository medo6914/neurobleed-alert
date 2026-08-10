import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../alerts/widgets/alert_overlay.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex(String location) {
    if (location.startsWith('/reports')) return 1;
    if (location.startsWith('/devices')) return 2;
    if (location.startsWith('/history') || location.startsWith('/record')) {
      return 3;
    }
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/admin')) {
      return 4;
    }
    return 0;
  }

  void _onTap(int index, String location) {
    switch (index) {
      case 0:
        if (location != '/dashboard') context.go('/dashboard');
        break;
      case 1:
        context.go('/reports');
        break;
      case 2:
        context.go('/devices');
        break;
      case 3:
        context.go('/history');
        break;
      case 4:
        context.go('/profile');
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
          decoration: const BoxDecoration(
            color: Color(0xFF0D1220),
            border: Border(
              top: BorderSide(
                color: Color(0xFF1A237E),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 70,
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) => _onTap(index, location),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: const Color(0xFF2196F3),
                unselectedItemColor: const Color(0xFF8E8E93),
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'الرئيسية',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.insert_chart_outlined),
                    activeIcon: Icon(Icons.insert_chart),
                    label: 'التقارير',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.devices_outlined),
                    activeIcon: Icon(Icons.devices),
                    label: 'الجهاز',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: 'السجل',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
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
