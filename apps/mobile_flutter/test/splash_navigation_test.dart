import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import '../lib/core/auth/auth_provider.dart';
import '../lib/core/router/app_router.dart' as app_router;
import '../lib/features/auth/login_screen.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier()
      : super(ApiClient(), SecureStorageService(), checkOnInit: false) {
    Future<void>.microtask(() {
      if (!mounted) return;
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
  }
}

void main() {
  testWidgets('splash resolves and navigates to login when not authenticated',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => _FixedAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final router =
        app_router.AppRouter(container.read(authGuardProvider)).router;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
