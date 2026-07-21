import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGuard extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
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

    if (!_isAuthenticated && !isPublicRoute) {
      return '/login';
    }

    if (_isAuthenticated && isPublicRoute) {
      return '/dashboard';
    }

    return null;
  }
}
