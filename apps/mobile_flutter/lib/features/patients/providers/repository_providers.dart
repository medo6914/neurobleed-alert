import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return PatientRepository(
    apiClient: apiClient,
    patientApi: PatientApi(apiClient),
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});

final admissionRepositoryProvider = Provider<AdmissionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return AdmissionRepository(
    apiClient: apiClient,
    admissionApi: AdmissionApi(apiClient),
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return NotesRepository(
    apiClient: apiClient,
    notesApi: NotesApi(apiClient),
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return DocumentsRepository(
    apiClient: apiClient,
    documentsApi: DocumentsApi(apiClient),
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return VitalsRepository(
    apiClient: apiClient,
    vitalsApi: VitalsApi(apiClient),
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return AlertRepository(
    apiClient: apiClient,
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueue = ref.watch(syncQueueProvider);
  return AuditRepository(
    apiClient: apiClient,
    errorHandler: errorHandler,
    logger: logger,
    syncQueue: syncQueue,
  );
});
