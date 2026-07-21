class AppConfig {
  static String get baseUrl {
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    );
  }

  static String get apiUrl => '$baseUrl/api/v1';
  static String get wsUrl => baseUrl.replaceFirst('http', 'ws');

  static bool get isProduction {
    return const bool.fromEnvironment('PRODUCTION', defaultValue: false);
  }

  static bool get useFirebaseEmulator {
    return const bool.fromEnvironment(
      'USE_FIREBASE_EMULATOR',
      defaultValue: true,
    );
  }

  static String get appVersion {
    return const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  }

  static String get environment {
    if (isProduction) return 'production';
    return 'development';
  }
}
