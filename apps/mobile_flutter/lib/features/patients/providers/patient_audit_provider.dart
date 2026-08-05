import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

final patientAuditProvider =
    FutureProvider.family<List<AuditRecord>, String>((ref, patientId) async {
  final repository = ref.watch(auditRepositoryProvider);
  final result = await repository.getAuditLog(patientId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (records) => records,
  );
});
