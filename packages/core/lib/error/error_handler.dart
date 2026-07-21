import 'package:dio/dio.dart';
import '../network/api_exceptions.dart';
import '../logging/logger.dart';
import 'failure.dart';

class ErrorHandler {
  final AppLogger _logger;

  ErrorHandler(this._logger);

  Failure handle(dynamic error, {StackTrace? stackTrace}) {
    _logger.error(
      'Error occurred',
      error: error,
      stackTrace: stackTrace,
    );

    if (error is Failure) {
      return error;
    }

    if (error is DioException) {
      return _handleDioException(error);
    }

    if (error is ApiException) {
      return _handleApiException(error);
    }

    if (error is FormatException) {
      return const ValidationFailure(
        message: 'Invalid data format',
        code: 'INVALID_FORMAT',
      );
    }

    return ServerFailure(
      message: error.toString(),
      code: 'UNKNOWN_ERROR',
    );
  }

  Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure(
          message: 'Connection timed out',
          code: 'TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'No internet connection',
          code: 'NO_INTERNET',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final data = error.response?.data;
        final message = data is Map
            ? (data['message'] ?? data['detail'] ?? 'Unknown error') as String
            : 'Unknown error';

        if (statusCode == 401) {
          return AuthFailure(
            message: message,
            code: 'UNAUTHORIZED',
          );
        }
        if (statusCode == 404) {
          return NotFoundFailure(
            message: message,
            code: 'NOT_FOUND',
          );
        }
        if (statusCode == 422) {
          return ValidationFailure(
            message: message,
            code: 'VALIDATION_ERROR',
          );
        }
        if (statusCode >= 500) {
          return ServerFailure(
            message: message,
            statusCode: statusCode,
            code: 'SERVER_ERROR',
          );
        }
        return ServerFailure(
          message: message,
          statusCode: statusCode,
          code: 'HTTP_$statusCode',
        );

      case DioExceptionType.cancel:
        return NetworkFailure(
          message: 'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.badCertificate:
        return NetworkFailure(
          message: 'Bad certificate',
          code: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
        return NetworkFailure(
          message: error.message ?? 'Unknown network error',
          code: 'UNKNOWN_NETWORK',
        );
      case DioExceptionType.transformTimeout:
        return TimeoutFailure(
          message: 'Transform timed out',
          code: 'TRANSFORM_TIMEOUT',
        );
    }
  }

  Failure _handleApiException(ApiException error) {
    if (error is NetworkException) {
      return NetworkFailure(
        message: error.message,
        code: 'NETWORK',
      );
    }
    if (error is AuthException) {
      return AuthFailure(
        message: error.message,
        code: 'AUTH',
      );
    }
    if (error is NotFoundException) {
      return NotFoundFailure(
        message: error.message,
        code: 'NOT_FOUND',
      );
    }
    if (error is ValidationException) {
      return ValidationFailure(
        message: error.message,
        errors: error.errors,
        code: 'VALIDATION',
      );
    }
    if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
        code: 'SERVER',
      );
    }
    return ServerFailure(
      message: error.message,
      code: 'API_ERROR',
    );
  }
}
