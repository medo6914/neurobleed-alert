import 'dart:convert';
import 'dart:html';
import '../sync/sync_queue.dart';

class PersistentSyncQueue extends SyncQueue {
  static const _storageKey = 'neurobleed_sync_queue';

  Future<void> init() async {
    final stored = window.localStorage[_storageKey];
    if (stored != null && stored.isNotEmpty) {
      final list = jsonDecode(stored) as List<dynamic>;
      final entries = list
          .map((e) => SyncQueueEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entriesInternal.addAll(entries);
    }
  }

  @override
  Future<void> add(SyncQueueEntry entry) async {
    await super.add(entry);
    _persist();
  }

  @override
  Future<void> addAll(List<SyncQueueEntry> entries) async {
    await super.addAll(entries);
    _persist();
  }

  @override
  Future<void> remove(String id) async {
    await super.remove(id);
    _persist();
  }

  @override
  Future<void> incrementRetry(String id, String error) async {
    await super.incrementRetry(id, error);
    _persist();
  }

  @override
  Future<void> markFailed(String id) async {
    await super.markFailed(id);
    _persist();
  }

  @override
  Future<void> clear() async {
    await super.clear();
    _persist();
  }

  @override
  Future<void> clearCompleted() async {
    await super.clearCompleted();
    _persist();
  }

  void _persist() {
    final content = jsonEncode(entriesInternal.map((e) => e.toJson()).toList());
    window.localStorage[_storageKey] = content;
  }
}
