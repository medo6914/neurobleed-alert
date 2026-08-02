import 'dart:convert';
import 'dart:html';
import 'dart:math';

class OfflineCache {
  static const _prefix = 'neurobleed_cache_';
  static const _keysKey = 'neurobleed_cache_keys_v1';
  static final _random = Random();

  Future<void> init() async {
    _initKeyTracker();
  }

  String? get cachePath => 'window.localStorage (web)';

  Future<void> put(String key, dynamic value) async {
    final json = jsonEncode(value);
    final encoded = base64Encode(utf8.encode(json));
    window.localStorage[_prefix + key] = encoded;
    _addTrackedKey(key);
  }

  Future<T?> get<T>(String key,
      {T Function(Map<String, dynamic>)? fromJson}) async {
    try {
      final encoded = window.localStorage[_prefix + key];
      if (encoded != null) {
        final decoded = utf8.decode(base64Decode(encoded));
        final data = jsonDecode(decoded);
        return fromJson != null
            ? fromJson(data as Map<String, dynamic>)
            : data as T;
      }
    } catch (_) {
    }
    return null;
  }

  Future<void> remove(String key) async {
    window.localStorage.remove(_prefix + key);
    _removeTrackedKey(key);
  }

  Future<void> clearByPrefix(String prefix) async {
    final keys = _getTrackedKeys();
    final toRemove = keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in toRemove) {
      window.localStorage.remove(_prefix + key);
      _removeTrackedKey(key);
    }
  }

  Future<void> clear() async {
    final keys = _getTrackedKeys();
    for (final key in keys) {
      window.localStorage.remove(_prefix + key);
    }
    window.localStorage.remove(_keysKey);
  }

  void _initKeyTracker() {
    if (window.localStorage[_keysKey] == null) {
      window.localStorage[_keysKey] = '[]';
    }
  }

  List<String> _getTrackedKeys() {
    final stored = window.localStorage[_keysKey];
    if (stored == null || stored.isEmpty) return [];
    try {
      return (jsonDecode(stored) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  void _setTrackedKeys(List<String> keys) {
    window.localStorage[_keysKey] = jsonEncode(keys);
  }

  void _addTrackedKey(String key) {
    final keys = _getTrackedKeys();
    if (!keys.contains(key)) {
      keys.add(key);
      _setTrackedKeys(keys);
    }
  }

  void _removeTrackedKey(String key) {
    final keys = _getTrackedKeys();
    keys.remove(key);
    _setTrackedKeys(keys);
  }
}
