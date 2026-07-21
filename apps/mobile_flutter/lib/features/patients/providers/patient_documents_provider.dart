import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

final patientDocumentsProvider = FutureProvider.family<List<MedicalDocument>, String>((ref, patientId) async {
  final repository = ref.watch(documentsRepositoryProvider);
  final result = await repository.listDocuments(patientId: patientId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (docs) => docs,
  );
});
