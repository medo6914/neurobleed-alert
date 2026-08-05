import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  group('Failure', () {
    test('ServerFailure has correct message', () {
      const failure = ServerFailure(message: 'Server error', statusCode: 500);
      expect(failure.message, 'Server error');
      expect(failure.statusCode, 500);
    });

    test('NetworkFailure has correct message', () {
      const failure =
          NetworkFailure(message: 'No internet', code: 'NO_INTERNET');
      expect(failure.message, 'No internet');
      expect(failure.code, 'NO_INTERNET');
    });

    test('AuthFailure has correct message', () {
      const failure = AuthFailure(message: 'Unauthorized');
      expect(failure.message, 'Unauthorized');
    });

    test('ValidationFailure has errors', () {
      const failure = ValidationFailure(
        message: 'Validation failed',
        errors: {
          'email': ['Invalid']
        },
      );
      expect(failure.errors, isNotNull);
    });

    test('All failure types are constructable', () {
      expect(const ServerFailure(message: 'a'), isA<ServerFailure>());
      expect(const NetworkFailure(message: 'a'), isA<NetworkFailure>());
      expect(const AuthFailure(message: 'a'), isA<AuthFailure>());
      expect(const ValidationFailure(message: 'a'), isA<ValidationFailure>());
      expect(const CacheFailure(message: 'a'), isA<CacheFailure>());
      expect(const NotFoundFailure(message: 'a'), isA<NotFoundFailure>());
      expect(const TimeoutFailure(message: 'a'), isA<TimeoutFailure>());
    });
  });

  group('SyncQueueEntry', () {
    test('toJson and fromJson roundtrip', () {
      final entry = SyncQueueEntry(
        id: '1',
        entityType: 'patient',
        operation: 'create',
        data: {'name': 'Test'},
        createdAt: DateTime(2024, 1, 1),
      );
      final json = entry.toJson();
      final restored = SyncQueueEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.entityType, entry.entityType);
      expect(restored.operation, entry.operation);
      expect(restored.data, entry.data);
      expect(restored.createdAt, entry.createdAt);
    });

    test('copyWith preserves fields', () {
      final entry = SyncQueueEntry(
        id: '1',
        entityType: 'patient',
        operation: 'create',
        data: {},
        createdAt: DateTime(2024, 1, 1),
      );
      final updated = entry.copyWith(retryCount: 2, lastError: 'err');
      expect(updated.retryCount, 2);
      expect(updated.lastError, 'err');
      expect(updated.id, '1');
    });
  });

  group('EnvConfig', () {
    test('fromDartDefine creates valid instance', () {
      final config = EnvConfig.fromDartDefine();
      expect(config.apiBaseUrl, isNotEmpty);
      expect(config.wsBaseUrl, isNotEmpty);
      expect(config.featureFlags, contains('offlineFirst'));
      expect(config.firebaseConfig, isA<Map<String, String>>());
    });

    test('instance is singleton', () {
      final a = EnvConfig.instance;
      final b = EnvConfig.instance;
      expect(identical(a, b), isTrue);
    });

    test('static convenience getters work', () {
      EnvConfig.fromDartDefine();
      expect(EnvConfig.offlineFirst, isA<bool>());
      expect(EnvConfig.syncEnabled, isA<bool>());
    });
  });

  group('SyncQueue', () {
    test('add and getPending', () async {
      final queue = SyncQueue();
      expect(await queue.getPendingCount(), 0);
      await queue.add(SyncQueueEntry(
        id: '1',
        entityType: 'test',
        operation: 'create',
        data: {},
        createdAt: DateTime.now(),
      ));
      expect(await queue.getPendingCount(), 1);
    });

    test('remove entry', () async {
      final queue = SyncQueue();
      await queue.add(SyncQueueEntry(
        id: '1',
        entityType: 'test',
        operation: 'create',
        data: {},
        createdAt: DateTime.now(),
      ));
      await queue.remove('1');
      expect(await queue.getPendingCount(), 0);
    });
  });
}
