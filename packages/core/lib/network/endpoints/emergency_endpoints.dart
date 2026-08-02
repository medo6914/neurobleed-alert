import 'package:dio/dio.dart';
import '../api_client.dart';

class EmergencyEndpoints {
  static const String baseSos = '/v1/emergency/sos';
  static const String baseEvents = '/v1/emergency/events';
  static const String baseContacts = '/v1/emergency/contacts';
  static String eventById(String id) => '/v1/emergency/events/$id';
  static String resolveEvent(String id) => '/v1/emergency/events/$id/resolve';
  static String contactById(String id) => '/v1/emergency/contacts/$id';
}

class EmergencyApi {
  final ApiClient _client;

  EmergencyApi(this._client);

  Future<Response> triggerSos(Map<String, dynamic> data) =>
      _client.post(EmergencyEndpoints.baseSos, data: data);

  Future<Response> listEvents({
    String? patientId,
    String? status,
    int page = 1,
    int limit = 20,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (patientId != null) params['patient_id'] = patientId;
    if (status != null) params['status'] = status;
    return _client.get(EmergencyEndpoints.baseEvents, queryParameters: params);
  }

  Future<Response> getEvent(String id) =>
      _client.get(EmergencyEndpoints.eventById(id));

  Future<Response> resolveEvent(String id) =>
      _client.post(EmergencyEndpoints.resolveEvent(id));

  Future<Response> createContact(Map<String, dynamic> data) =>
      _client.post(EmergencyEndpoints.baseContacts, data: data);

  Future<Response> listContacts({String? patientId}) {
    final params = <String, dynamic>{};
    if (patientId != null) params['patient_id'] = patientId;
    return _client.get(EmergencyEndpoints.baseContacts, queryParameters: params);
  }

  Future<Response> getContact(String id) =>
      _client.get(EmergencyEndpoints.contactById(id));

  Future<Response> updateContact(String id, Map<String, dynamic> data) =>
      _client.put(EmergencyEndpoints.contactById(id), data: data);

  Future<Response> deleteContact(String id) =>
      _client.delete(EmergencyEndpoints.contactById(id));
}
