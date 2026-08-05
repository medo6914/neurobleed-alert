import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

final patientVitalsProvider =
    FutureProvider.family<List<VitalsRecord>, String>((ref, patientId) async {
  final repository = ref.watch(vitalsRepositoryProvider);
  final result = await repository.listVitals(patientId: patientId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (vitals) => vitals,
  );
});

final latestVitalsProvider =
    FutureProvider.family<VitalsRecord?, String>((ref, patientId) async {
  final repository = ref.watch(vitalsRepositoryProvider);
  final result = await repository.getLatestVitals(patientId);
  return result.fold(
    (failure) => null,
    (vitals) => vitals,
  );
});
