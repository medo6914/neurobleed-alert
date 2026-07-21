import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:shared/entities/medical_timeline.dart';

final patientTimelineProvider = FutureProvider.family<List<MedicalTimelineEntry>, String>((ref, patientId) async {
  final apiClient = ref.watch(apiClientProvider);
  final errorHandler = ref.watch(errorHandlerProvider);

  try {
    final response = await apiClient.get('/v1/patients/$patientId/timeline');
    final list = (response.data['data'] as List)
        .map((e) => MedicalTimelineEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  } catch (e) {
    throw Exception(errorHandler.handle(e).message);
  }
});
