import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OfflineCache {
  Directory? _cacheDir;

  Future<void> init() async {
    final dir = await getTemporaryDirectory();
    _cacheDir = Directory('${dir.path}/neurobleed_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  String? get cachePath => _cacheDir?.path;

  Future<void> put(String key, dynamic value) async {
    final file = _file(key);
    final json = jsonEncode(value);
    final encoded = base64Encode(utf8.encode(json));
    await file.writeAsString(encoded);
  }

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
    } catch (_) {}
    return null;
  }

  Future<void> remove(String key) async {
    final file = _file(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearByPrefix(String prefix) async {
    if (_cacheDir == null) return;
    final files = _cacheDir!.listSync().whereType<File>();
    for (final f in files) {
      if (f.path.contains(prefix)) {
        await f.delete();
      }
    }
  }

  Future<void> clear() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create();
    }
  }

  File _file(String key) => File('${_cacheDir!.path}/$key.json');
}
