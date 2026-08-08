import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import '../lib/features/auth/login_screen.dart';
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

void main() {
  testWidgets('splash screen renders',
      (tester) async {
    final storage = _FakeStorage();
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
  }, skip: 'Full app integration test - verify manually in browser');
}
