import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final liveVitalsStateProvider = StateNotifierProvider<LiveVitalsNotifier, Map<String, Map<String, dynamic>>>((ref) {
  return LiveVitalsNotifier(ref);
});

class LiveVitalsNotifier extends StateNotifier<Map<String, Map<String, dynamic>>> {
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  LiveVitalsNotifier(this._ref) : super({}) {
    final client = _ref.read(webSocketClientProvider);
    _subscription = client.messages.listen(_onMessage);
  }

  void _onMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    if (type == 'vitals_update') {
      final patientId = message['patient_id'] as String?;
      if (patientId != null) {
        state = {...state, patientId: message};
      }
    }
  }

  void clearPatient(String patientId) {
    final updated = Map<String, Map<String, dynamic>>.from(state);
    updated.remove(patientId);
    state = updated;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final patientLiveVitalsProvider = Provider.family<Map<String, dynamic>?, String>((ref, patientId) {
  final vitalsMap = ref.watch(liveVitalsStateProvider);
  return vitalsMap[patientId];
});
