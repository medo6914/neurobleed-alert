import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

class EmergencySosState {
  final bool isLoading;
  final bool isSending;
  final bool sent;
  final String? error;
  final Map<String, dynamic>? sosResult;
  final List<Map<String, dynamic>> contacts;
  final List<Map<String, dynamic>> events;

  const EmergencySosState({
    this.isLoading = false,
    this.isSending = false,
    this.sent = false,
    this.error,
    this.sosResult,
    this.contacts = const [],
    this.events = const [],
  });

  EmergencySosState copyWith({
    bool? isLoading,
    bool? isSending,
    bool? sent,
    String? error,
    Map<String, dynamic>? sosResult,
    List<Map<String, dynamic>>? contacts,
    List<Map<String, dynamic>>? events,
    bool clearError = false,
  }) {
    return EmergencySosState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      sent: sent ?? this.sent,
      error: clearError ? null : (error ?? this.error),
      sosResult: sosResult ?? this.sosResult,
      contacts: contacts ?? this.contacts,
      events: events ?? this.events,
    );
  }
}

class EmergencyNotifier extends StateNotifier<EmergencySosState> {
  final ApiClient _apiClient;

  EmergencyNotifier(this._apiClient) : super(const EmergencySosState());

  Future<void> triggerSos({
    required String patientId,
    String sosType = 'manual',
    double? lat,
    double? lng,
    String? notes,
  }) async {
    state = state.copyWith(isSending: true, sent: false, error: null);
    try {
      final response = await _apiClient.post('/v1/emergency/sos', data: {
        'patient_id': patientId,
        'sos_type': sosType,
        'location_lat': lat,
        'location_lng': lng,
        'notes': notes,
      });
      state = state.copyWith(
        isSending: false,
        sent: true,
        sosResult: response.data as Map<String, dynamic>,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Future<void> loadEvents({String? patientId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, dynamic>{};
      if (patientId != null) params['patient_id'] = patientId;
      final response = await _apiClient.get('/v1/emergency/events', queryParameters: params);
      state = state.copyWith(
        isLoading: false,
        events: (response.data as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> resolveEvent(String eventId) async {
    try {
      await _apiClient.post('/v1/emergency/events/$eventId/resolve');
      state = state.copyWith(sosResult: null, sent: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadContacts({String? patientId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, dynamic>{};
      if (patientId != null) params['patient_id'] = patientId;
      final response = await _apiClient.get('/v1/emergency/contacts', queryParameters: params);
      state = state.copyWith(
        isLoading: false,
        contacts: (response.data as List).cast<Map<String, dynamic>>(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createContact(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/v1/emergency/contacts', data: data);
      await loadContacts(patientId: data['patient_id'] as String?);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteContact(String contactId, {String? patientId}) async {
    try {
      await _apiClient.delete('/v1/emergency/contacts/$contactId');
      if (patientId != null) await loadContacts(patientId: patientId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void reset() {
    state = const EmergencySosState();
  }
}

final emergencyProvider = StateNotifierProvider<EmergencyNotifier, EmergencySosState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmergencyNotifier(apiClient);
});
