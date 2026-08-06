import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import '../lib/app/app.dart';
import '../lib/features/auth/login_screen.dart';
import '../lib/features/auth/onboarding_screen.dart';
import '../lib/features/auth/splash_screen.dart';

class _FakeStorage extends SecureStorageService {
  final Map<String, String> store = {};
  @override
  Future<void> write({required dynamic key, required dynamic value}) async {
    store[key as String] = value as String;
  }

  @override
  Future<String?> read({required dynamic key}) async {
    return store[key as String];
  }

  @override
  Future<void> deleteAll() async {
    store.clear();
  }

  @override
  Future<void> delete({required dynamic key}) async {
    store.remove(key as String);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

void main() {
  testWidgets('boot: no token -> onboarding (splash never hangs)',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(_FakeStorage()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NeuroBleedApp(),
      ),
    );

    for (var i = 0; i < 5 && find.byType(SplashScreen).evaluate().isNotEmpty;
        i++) {
      await _settle(tester);
    }

    expect(find.byType(SplashScreen), findsNothing,
        reason: 'splash must not persist');
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('boot: stored token without remember-me -> login screen',
      (tester) async {
    final storage = _FakeStorage();
    storage.store['auth_token'] = 't';
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NeuroBleedApp(),
      ),
    );

    for (var i = 0; i < 5 && find.byType(SplashScreen).evaluate().isNotEmpty;
        i++) {
      await _settle(tester);
    }

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}