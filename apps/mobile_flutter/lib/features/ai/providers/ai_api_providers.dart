import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiApiProvider = Provider<AIApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AIApi(apiClient);
});
