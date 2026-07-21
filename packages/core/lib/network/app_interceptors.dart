import 'package:dio/dio.dart';
import '../logging/logger.dart';
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;

  AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.path.contains('/auth/')) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final newToken = response.data['token'] as String;
            final newRefreshToken = response.data['refreshToken'] as String?;

            await _storage.saveToken(newToken);
            if (newRefreshToken != null) {
              await _storage.saveRefreshToken(newRefreshToken);
            }

            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await _dio.fetch(err.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        } catch (_) {
          await _storage.clearAll();
        }
      }
    }
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final Duration _baseDelay;

  RetryInterceptor(
    this._dio, {
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
  })  : _maxRetries = maxRetries,
        _baseDelay = baseDelay;

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryCount = _getRetryCount(err.requestOptions);

    if (retryCount >= _maxRetries) {
      handler.next(err);
      return;
    }

    final delay = _baseDelay * (1 << retryCount);
    await Future.delayed(delay);

    try {
      final options = err.requestOptions;
      _setRetryCount(options, retryCount + 1);
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } catch (e) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  int _getRetryCount(RequestOptions options) {
    return (options.extra['_retryCount'] as int?) ?? 0;
  }

  void _setRetryCount(RequestOptions options, int count) {
    options.extra['_retryCount'] = count;
  }
}

class LoggingInterceptor extends Interceptor {
  final AppLogger _logger;

  LoggingInterceptor(this._logger);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    _logger.debug(
      '${options.method} ${options.path}',
      extra: {
        'baseUrl': options.baseUrl,
        'queryParameters': options.queryParameters,
        'headers': _sanitizeHeaders(options.headers),
        'data': options.data,
      },
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.debug(
      '${response.statusCode} ${response.requestOptions.path}',
      extra: {
        'data': response.data is List
            ? 'List(${response.data.length})'
            : response.data,
      },
    );
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _logger.error(
      '${err.response?.statusCode ?? 'ERR'} ${err.requestOptions.path}',
      error: err,
      extra: {
        'type': err.type.name,
        'message': err.message,
      },
    );
    handler.next(err);
  }

  Map<String, String> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, String>{};
    headers.forEach((key, value) {
      if (key.toLowerCase() == 'authorization') {
        sanitized[key] = 'Bearer ***';
      } else {
        sanitized[key] = value.toString();
      }
    });
    return sanitized;
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final statusCode = err.response?.statusCode;
    final message = _extractMessage(err);

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: NetworkException(message),
            message: message,
          ),
        );
        break;

      case DioExceptionType.badResponse:
        final exception =
            _mapStatusCode(statusCode, message, err.response?.data);
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: exception,
            message: message,
          ),
        );
        break;

      case DioExceptionType.connectionError:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: NetworkException('No internet connection'),
            message: 'No internet connection',
          ),
        );
        break;

      default:
        handler.next(err);
    }
  }

  String _extractMessage(DioException err) {
    final data = err.response?.data;
    if (data is Map) {
      return (data['message'] ??
          data['detail'] ??
          err.message ??
          'Unknown error') as String;
    }
    return err.message ?? 'Unknown error';
  }

  ApiException _mapStatusCode(int? statusCode, String message, dynamic data) {
    switch (statusCode) {
      case 401:
        return AuthException(message);
      case 404:
        return NotFoundException(message);
      case 422:
        final errors =
            data is Map ? data['errors'] as Map<String, List<String>>? : null;
        return ValidationException(message, errors: errors);
      case 500:
        return ServerException(message);
      default:
        return ApiException(message: message, statusCode: statusCode);
    }
  }
}
