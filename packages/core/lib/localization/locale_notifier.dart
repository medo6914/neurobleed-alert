import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/providers.dart';
import '../storage/secure_storage_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final SecureStorageService _storage;

  LocaleNotifier(this._storage) : super(const Locale('en', 'US'));

  Future<void> loadSavedLocale() async {
    final saved = await _storage.getLocale();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.saveLocale(locale);
  }

  Future<void> toggleLanguage() async {
    if (state.languageCode == 'en') {
      await setLocale(const Locale('ar', 'SA'));
    } else {
      await setLocale(const Locale('en', 'US'));
    }
  }

  Future<void> setEnglish() async {
    await setLocale(const Locale('en', 'US'));
  }

  Future<void> setArabic() async {
    await setLocale(const Locale('ar', 'SA'));
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocaleNotifier(storage);
});

final localeNotifierProvider = localeProvider;
