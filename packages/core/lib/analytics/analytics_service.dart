import '../env/env_config.dart';
import '../logging/logger.dart';

class AnalyticsService {
  final AppLogger _logger;
  final bool _isProduction;

  AnalyticsService({required AppLogger logger})
      : _logger = logger,
        _isProduction = EnvConfig.instance.isProduction;

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (_isProduction) {
      try {
        await _logToFirebase(name, parameters: parameters);
      } catch (e) {
        _logger.error('Failed to log analytics event', error: e);
      }
    } else {
      _logger.debug('Analytics event: $name', extra: parameters);
    }
  }

  Future<void> setUserId(String? userId) async {
    if (_isProduction) {
      try {
        await _setFirebaseUserId(userId);
      } catch (e) {
        _logger.error('Failed to set analytics user id', error: e);
      }
    } else {
      _logger.debug('Analytics setUserId: $userId');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    if (_isProduction) {
      try {
        await _setFirebaseUserProperty(name, value);
      } catch (e) {
        _logger.error('Failed to set analytics user property', error: e);
      }
    } else {
      _logger.debug('Analytics setUserProperty: $name = $value');
    }
  }

  Future<void> _logToFirebase(String name,
      {Map<String, dynamic>? parameters}) async {
    // Firebase Analytics integration placeholder
    // In production, this would call FirebaseAnalytics.instance.logEvent(...)
    _logger.debug('Firebase analytics event: $name');
  }

  Future<void> _setFirebaseUserId(String? userId) async {
    // Firebase Analytics integration placeholder
  }

  Future<void> _setFirebaseUserProperty(String name, String value) async {
    // Firebase Analytics integration placeholder
  }
}
