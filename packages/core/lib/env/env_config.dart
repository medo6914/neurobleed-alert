class EnvConfig {
  final String apiBaseUrl;
  final String wsBaseUrl;
  final bool isProduction;
  final String environmentName;
  final String appVersion;
  final String buildNumber;
  final Map<String, bool> featureFlags;

  EnvConfig._({
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.isProduction,
    required this.environmentName,
    required this.appVersion,
    required this.buildNumber,
    required this.featureFlags,
  });

  static EnvConfig? _instance;

  static EnvConfig get instance {
    if (_instance == null) {
      _instance = EnvConfig.fromDartDefine();
    }
    return _instance!;
  }

  static bool get offlineFirst => instance.featureFlags['offlineFirst'] ?? true;
  static bool get syncEnabled => instance.featureFlags['syncEnabled'] ?? true;

  factory EnvConfig.fromDartDefine() {
    final apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    );
    final isProduction = const bool.fromEnvironment(
      'PRODUCTION',
      defaultValue: false,
    );
    _instance = EnvConfig._(
      apiBaseUrl: apiBaseUrl,
      wsBaseUrl: apiBaseUrl.replaceFirst('http', 'ws'),
      isProduction: isProduction,
      environmentName: isProduction ? 'production' : 'development',
      appVersion:
          const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
      buildNumber:
          const String.fromEnvironment('BUILD_NUMBER', defaultValue: '1'),
      featureFlags: {
        'offlineFirst': const bool.fromEnvironment('FEATURE_OFFLINE_FIRST',
            defaultValue: true),
        'syncEnabled': const bool.fromEnvironment('FEATURE_SYNC_ENABLED',
            defaultValue: true),
      },
    );
    return _instance!;
  }

  Map<String, String> get firebaseConfig => {
        'apiKey':
            const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
        'projectId': const String.fromEnvironment('FIREBASE_PROJECT_ID',
            defaultValue: ''),
        'appId':
            const String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
      };
}
