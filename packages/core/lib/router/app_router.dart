import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_guard.dart';

class AppRouter {
  final AuthGuard _authGuard;

  AppRouter(this._authGuard);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authGuard,
    redirect: _authGuard.guard,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen')),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Register Screen')),
        ),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OTP Screen')),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Dashboard')),
            ),
          ),
          GoRoute(
            path: '/patients',
            name: 'patients',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Patient List')),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'patient-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                    body: Center(child: Text('Patient Detail: $id')),
                  );
                },
              ),
              GoRoute(
                path: 'create',
                name: 'patient-create',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Create Patient')),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/devices',
            name: 'devices',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Device List')),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'device-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return Scaffold(
                    body: Center(child: Text('Device Detail: $id')),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/monitoring',
            name: 'monitoring',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Live Monitoring')),
            ),
            routes: [
              GoRoute(
                path: ':patientId',
                name: 'monitoring-patient',
                builder: (context, state) {
                  final patientId = state.pathParameters['patientId']!;
                  return Scaffold(
                    body: Center(child: Text('Monitoring: $patientId')),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Alerts')),
            ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Reports')),
            ),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Notifications')),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Settings')),
            ),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Panel')),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
