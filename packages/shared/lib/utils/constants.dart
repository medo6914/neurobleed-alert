class ApiConstants {
  static const String apiVersion = 'v1';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}

class VitalNormalRanges {
  static const heartRateMin = 60;
  static const heartRateMax = 100;
  static const oxygenSaturationMin = 95;
  static const oxygenSaturationMax = 100;
  static const systolicBPMin = 90;
  static const systolicBPMax = 140;
  static const diastolicBPMin = 60;
  static const diastolicBPMax = 90;
  static const temperatureMin = 36.0;
  static const temperatureMax = 37.5;
  static const respiratoryRateMin = 12;
  static const respiratoryRateMax = 20;
  static const icpMin = 5;
  static const icpMax = 15;
  static const cppMin = 60;
  static const cppMax = 100;
}

class AppConstants {
  static const String appName = 'NeuroBleed Alert';
  static const String companyName = 'NeuroBleed';
  static const int sessionTimeoutMinutes = 60;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
}
