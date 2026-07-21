import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Lightweight file-based JSON cache for offline data.
///
/// Stores entities as individual JSON files under a dedicated cache
/// directory.  Used by [DatabaseService] as a read-through / write-through
/// cache when the device is offline.
///
/// All cached values are base64-encoded to prevent casual inspection
/// of medical data at rest on the filesystem.
class OfflineCache {
  Directory? _cacheDir;

  /// Initialise the cache directory.
  ///
  /// Must be called once before any read/write operation (typically in
  /// your app's bootstrap logic).
  Future<void> init() async {
    final dir = await getTemporaryDirectory();
    _cacheDir = Directory('${dir.path}/neurobleed_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  /// The cache directory path for diagnostic purposes.
  String? get cachePath => _cacheDir?.path;

  // ---------------------------------------------------------------------------
  // Key-value helpers
  // ---------------------------------------------------------------------------

  /// Store [value] under [key] as a JSON file.
  Future<void> put(String key, dynamic value) async {
    final file = _file(key);
    final json = jsonEncode(value);
    final encoded = base64Encode(utf8.encode(json));
    await file.writeAsString(encoded);
  }

  /// Retrieve the value stored under [key], or `null` when missing.
  Future<T?> get<T>(String key,
      {T Function(Map<String, dynamic>)? fromJson}) async {
    try {
      final file = _file(key);
      if (await file.exists()) {
        final encoded = await file.readAsString();
        final decoded = utf8.decode(base64Decode(encoded));
        final data = jsonDecode(decoded);
        return fromJson != null
            ? fromJson(data as Map<String, dynamic>)
            : data as T;
      }
    } catch (_) {
      // Corrupted file – treat as cache miss.
    }
    return null;
  }

  /// Remove the file stored under [key].
  Future<void> remove(String key) async {
    final file = _file(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Remove all cache entries whose key starts with [prefix].
  ///
  /// Useful for invalidating a whole entity type (e.g. `clearByPrefix('patient_')`).
  Future<void> clearByPrefix(String prefix) async {
    if (_cacheDir == null) return;
    final files = _cacheDir!.listSync().whereType<File>();
    for (final f in files) {
      if (f.path.contains(prefix)) {
        await f.delete();
      }
    }
  }

  /// Wipe every cached entry.
  Future<void> clear() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create();
    }
  }

  File _file(String key) => File('${_cacheDir!.path}/$key.json');
}
