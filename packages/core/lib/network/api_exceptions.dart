class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class NetworkException extends ApiException {
  const NetworkException(String message)
      : super(message: message, statusCode: null);
}

class AuthException extends ApiException {
  const AuthException(String message)
      : super(message: message, statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException(String message)
      : super(message: message, statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException(String message, {this.errors})
      : super(message: message, statusCode: 422);
}

class ServerException extends ApiException {
  const ServerException([String message = 'Internal server error'])
      : super(message: message, statusCode: 500);
}
