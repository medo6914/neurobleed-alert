import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

class FontSizeNotifier extends StateNotifier<String> {
  final SecureStorageService _storage;

  FontSizeNotifier(this._storage) : super('medium') {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final saved = await _storage.getFontSize();
    state = saved;
  }

  Future<void> setFontSize(String size) async {
    state = size;
    await _storage.saveFontSize(size);
  }
}
