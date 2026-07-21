import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;

  ApiClient([Dio? dio]) : _dio = dio ?? _createDefaultDio();

  static Dio _createDefaultDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    return dio;
  }

  Dio get dio => _dio;

  void configureTimeout({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    _dio.options.connectTimeout = connectTimeout ?? _dio.options.connectTimeout;
    _dio.options.receiveTimeout = receiveTimeout ?? _dio.options.receiveTimeout;
    _dio.options.sendTimeout = sendTimeout ?? _dio.options.sendTimeout;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> download(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      return await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  void setAuthToken(String token) {
    if (token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<String?> refreshAuthToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['token'] as String?;
        if (newToken != null && newToken.isNotEmpty) {
          setAuthToken(newToken);
          return newToken;
        }
      }
      return null;
    } on DioException {
      clearAuthToken();
      return null;
    }
  }

  CancelToken createCancelToken() => CancelToken();

  ApiException _handleError(DioException e) {
    if (e.error is ApiException) {
      return e.error as ApiException;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timed out');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 500;
        final data = e.response?.data;
        final message = data is Map
            ? ((data['detail'] ?? data['message'] ?? 'Unknown error') as String)
            : 'Unknown error';

        switch (statusCode) {
          case 401:
            return AuthException(message);
          case 404:
            return NotFoundException(message);
          case 422:
            final errors = data is Map
                ? data['errors'] as Map<String, List<String>>?
                : null;
            return ValidationException(message, errors: errors);
          case 500:
            return ServerException(message);
          default:
            return ApiException(message: message, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request cancelled');
      default:
        return const NetworkException('No internet connection');
    }
  }
}
