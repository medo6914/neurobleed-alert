import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'database_service.dart';
import 'offline_cache.dart';
import 'persistent_sync_queue.dart';

// ---------------------------------------------------------------------------
// Low-level storage providers
// ---------------------------------------------------------------------------

final offlineCacheProvider = Provider<OfflineCache>((ref) {
  return OfflineCache();
});

final persistentSyncQueueProvider = Provider<PersistentSyncQueue>((ref) {
  return PersistentSyncQueue();
});

// ---------------------------------------------------------------------------
// Database service
// ---------------------------------------------------------------------------

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  final syncQueue = ref.watch(persistentSyncQueueProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  final cache = ref.watch(offlineCacheProvider);
  final logger = ref.watch(loggerProvider);

  return DatabaseService(
    localDb: localDb,
    syncQueue: syncQueue,
    syncEngine: syncEngine,
    cache: cache,
    logger: logger,
  );
});
