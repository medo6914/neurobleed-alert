import 'package:dio/dio.dart';
import '../api_client.dart';

class VitalsEndpoints {
  static const String base = '/v1/vitals';
  static String byId(String id) => '/v1/vitals/$id';
  static String latest(String patientId) =>
      '/v1/vitals/patient/$patientId/latest';
  static String range(String patientId) =>
      '/v1/vitals/patient/$patientId/range';
}

class VitalsApi {
  final ApiClient _client;

  VitalsApi(this._client);

  Future<Response> getVital(String id) => _client.get(VitalsEndpoints.byId(id));

  Future<Response> createVital(Map<String, dynamic> data) =>
      _client.post(VitalsEndpoints.base, data: data);

  Future<Response> createBatch(List<Map<String, dynamic>> vitals) =>
      _client.post('${VitalsEndpoints.base}/batch', data: {'vitals': vitals});

  Future<Response> getLatestVitals(String patientId) =>
      _client.get(VitalsEndpoints.latest(patientId));

  Future<Response> getVitalsRange(
    String patientId, {
    required DateTime from,
    required DateTime to,
    int page = 1,
    int limit = 100,
  }) {
    return _client.get(
      VitalsEndpoints.range(patientId),
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
        'page': page,
        'limit': limit,
      },
    );
  }

  Future<Response> listVitals({
    String? patientId,
    String? deviceId,
    int page = 1,
    int limit = 50,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (patientId != null) params['patient_id'] = patientId;
    if (deviceId != null) params['device_id'] = deviceId;
    return _client.get(VitalsEndpoints.base, queryParameters: params);
  }
}
