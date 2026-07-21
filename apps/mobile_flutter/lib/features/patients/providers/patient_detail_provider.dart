import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

final patientDetailProvider = FutureProvider.family<Patient, String>((ref, id) async {
  final repository = ref.watch(patientRepositoryProvider);
  final result = await repository.getPatient(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (patient) => patient,
  );
});
