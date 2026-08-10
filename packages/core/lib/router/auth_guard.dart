import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGuard extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _role;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  void setAuthenticated(bool value, {String? role}) {
    _isAuthenticated = value;
    _role = role;
    _isInitialized = true;
    notifyListeners();
  }

  final List<String> _publicRoutes = const [
    '/splash',
    '/onboarding',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/verify-email',
    '/phone-verification',
    '/otp',
  ];

  String? guard(BuildContext context, GoRouterState state) {
    if (!_isInitialized) return '/splash';

    final location = state.matchedLocation;
    final isPublicRoute = _publicRoutes.any((r) => location == r);

    if (isSplashLocation(location)) {
      return _isAuthenticated ? getHome(role: _role) : '/login';
    }

    if (_isAuthenticated && isPublicRoute) {
      return getHome(role: _role);
    }

    if (_isAuthenticated && location == '/admin' && !_isSuperAdmin) {
      return '/dashboard';
    }

    if (!_isAuthenticated && !isPublicRoute) {
      return '/login';
    }

    return null;
  }

  bool isSplashLocation(String location) {
    return location == '/splash' || location == '/' || location.isEmpty;
  }

  String? getHome({String? role}) {
    if (role == 'super_admin' || role == 'admin') return '/admin';
    return '/dashboard';
  }

  bool get _isSuperAdmin => _role == 'super_admin';
}
