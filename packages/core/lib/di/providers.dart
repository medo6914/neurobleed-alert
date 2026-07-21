import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/analytics_service.dart';
import '../database/persistent_sync_queue.dart';
import '../env/env_config.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/app_interceptors.dart';
import '../network/network_info.dart';
import '../security/encryption_service.dart';
import '../storage/local_database_service.dart';
import '../storage/secure_storage_service.dart';
import '../sync/sync_engine.dart';

final envConfigProvider = Provider<EnvConfig>((ref) {
  return EnvConfig.fromDartDefine();
});

final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});

final dioProvider = Provider<Dio>((ref) {
  final envConfig = ref.watch(envConfigProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final logger = ref.watch(loggerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: envConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(secureStorage, dio),
    RetryInterceptor(dio),
    LoggingInterceptor(logger),
    ErrorInterceptor(),
  ]);

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  final logger = ref.watch(loggerProvider);
  return ErrorHandler(logger);
});

final syncQueueProvider = Provider<PersistentSyncQueue>((ref) {
  return PersistentSyncQueue();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  final apiClient = ref.watch(apiClientProvider);
  final logger = ref.watch(loggerProvider);
  return SyncEngine(
    networkInfo,
    syncQueue,
    apiClient,
    logger,
  );
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

final analyticsProvider = Provider<AnalyticsService>((ref) {
  final logger = ref.watch(loggerProvider);
  return AnalyticsService(logger: logger);
});
