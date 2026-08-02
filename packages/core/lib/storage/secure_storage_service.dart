import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService() : _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _onboardingKey = 'onboarding_complete';
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'app_locale';
  static const _rememberMeKey = 'remember_me';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> setOnboardingComplete() async {
    await _storage.write(key: _onboardingKey, value: 'true');
  }

  Future<bool> getOnboardingComplete() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  Future<void> clearOnboarding() async {
    await _storage.delete(key: _onboardingKey);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _storage.write(key: _themeModeKey, value: mode.name);
  }

  Future<ThemeMode> getThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveLocale(Locale locale) async {
    await _storage.write(
      key: _localeKey,
      value: '${locale.languageCode}_${locale.countryCode}',
    );
  }

  Future<Locale?> getLocale() async {
    final value = await _storage.read(key: _localeKey);
    if (value == null) return null;
    final parts = value.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  Future<void> clearLocale() async {
    await _storage.delete(key: _localeKey);
  }

  Future<void> saveRememberMe(bool remember) async {
    await _storage.write(key: _rememberMeKey, value: '$remember');
  }

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }
}
