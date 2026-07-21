import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import '../sync/sync_queue.dart';

/// A [SyncQueue] that persists its entries to disk so they survive app
/// restarts.
///
/// This is the backbone of the offline-first architecture: operations
/// queued while offline are written to a JSON file and replayed when
/// connectivity is restored.
class PersistentSyncQueue extends SyncQueue {
  static const _fileName = 'sync_queue.json';

  File? _file;

  /// Load any previously-persisted entries from disk.
  ///
  /// Call this once during app initialisation (after `WidgetsFlutterBinding`).
  Future<void> init() async {
    final dir = await getTemporaryDirectory();
    _file = File('${dir.path}/$_fileName');

    if (await _file!.exists()) {
      final content = await _file!.readAsString();
      if (content.isNotEmpty) {
        final list = jsonDecode(content) as List<dynamic>;
        final entries = list
            .map((e) => SyncQueueEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        entriesInternal.addAll(entries);
      }
    }
  }

  // --------------------------------------------------------------------------
  // Overrides – persist after every mutation
  // --------------------------------------------------------------------------

  @override
  Future<void> add(SyncQueueEntry entry) async {
    await super.add(entry);
    await _persist();
  }

  @override
  Future<void> addAll(List<SyncQueueEntry> entries) async {
    await super.addAll(entries);
    await _persist();
  }

  @override
  Future<void> remove(String id) async {
    await super.remove(id);
    await _persist();
  }

  @override
  Future<void> incrementRetry(String id, String error) async {
    await super.incrementRetry(id, error);
    await _persist();
  }

  @override
  Future<void> markFailed(String id) async {
    await super.markFailed(id);
    await _persist();
  }

  @override
  Future<void> clear() async {
    await super.clear();
    await _persist();
  }

  @override
  Future<void> clearCompleted() async {
    await super.clearCompleted();
    await _persist();
  }

  // --------------------------------------------------------------------------
  // Persistence
  // --------------------------------------------------------------------------

  Future<void> _persist() async {
    if (_file == null) return;
    final content = jsonEncode(entriesInternal.map((e) => e.toJson()).toList());
    await _file!.writeAsString(content);
  }
}
