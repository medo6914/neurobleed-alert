import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/router/app_router.dart' as app_router;
import '../../core/theme/theme_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authGuard = ref.watch(authGuardProvider);
  return app_router.AppRouter(authGuard).router;
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(secureStorageProvider));
});

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return PatientRepository(
    apiClient: ref.watch(apiClientProvider),
    patientApi: PatientApi(ref.watch(apiClientProvider)),
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});

final admissionRepositoryProvider = Provider<AdmissionRepository>((ref) {
  return AdmissionRepository(
    apiClient: ref.watch(apiClientProvider),
    admissionApi: AdmissionApi(ref.watch(apiClientProvider)),
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(
    apiClient: ref.watch(apiClientProvider),
    notesApi: NotesApi(ref.watch(apiClientProvider)),
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepository(
    apiClient: ref.watch(apiClientProvider),
    documentsApi: DocumentsApi(ref.watch(apiClientProvider)),
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository(
    apiClient: ref.watch(apiClientProvider),
    vitalsApi: VitalsApi(ref.watch(apiClientProvider)),
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(
    apiClient: ref.watch(apiClientProvider),
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(
    apiClient: ref.watch(apiClientProvider),
    errorHandler: ref.watch(errorHandlerProvider),
    logger: ref.watch(loggerProvider),
  );
});
