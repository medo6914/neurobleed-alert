import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  final LogLevel _minLevel;

  AppLogger({LogLevel minLevel = LogLevel.debug}) : _minLevel = minLevel;

  void debug(String message, {Map<String, dynamic>? extra}) {
    _log(LogLevel.debug, message, extra: extra);
  }

  void info(String message, {Map<String, dynamic>? extra}) {
    _log(LogLevel.info, message, extra: extra);
  }

  void warning(
    String message, {
    Map<String, dynamic>? extra,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message,
        extra: extra, error: error, stackTrace: stackTrace);
  }

  void error(
    String message, {
    Map<String, dynamic>? extra,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message,
        extra: extra, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? extra,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = _prefixForLevel(level);

    if (kDebugMode) {
      final buffer = StringBuffer('$prefix $timestamp $message');

      if (extra != null && extra.isNotEmpty) {
        buffer.write(' | extra: $extra');
      }
      if (error != null) {
        buffer.write(' | error: $error');
        if (stackTrace != null) {
          buffer.write(' | stackTrace: $stackTrace');
        }
      }

      debugPrint(buffer.toString());
    }
  }

  String _prefixForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARNING]';
      case LogLevel.error:
        return '[ERROR]';
    }
  }
}
