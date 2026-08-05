import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

final patientAlertsProvider =
    FutureProvider.family<List<AlertRecord>, String>((ref, patientId) async {
  final repository = ref.watch(alertRepositoryProvider);
  final result = await repository.getPatientAlerts(patientId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (alerts) => alerts,
  );
});
