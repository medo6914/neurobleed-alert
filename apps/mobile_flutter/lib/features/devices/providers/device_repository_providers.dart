import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return DeviceRepository(
    apiClient: apiClient,
    deviceApi: DeviceApi(apiClient),
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});
