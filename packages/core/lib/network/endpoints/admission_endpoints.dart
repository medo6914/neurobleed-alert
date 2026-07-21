import 'package:dio/dio.dart';
import '../api_client.dart';

class AdmissionEndpoints {
  static const String base = '/v1/admissions';
  static String byId(String id) => '/v1/admissions/$id';
  static String discharge(String id) => '/v1/admissions/$id/discharge';
  static String transfer(String id) => '/v1/admissions/$id/transfer';
}

class AdmissionApi {
  final ApiClient _client;

  AdmissionApi(this._client);

  Future<Response> getAdmission(String id) =>
      _client.get(AdmissionEndpoints.byId(id));

  Future<Response> createAdmission(Map<String, dynamic> data) =>
      _client.post(AdmissionEndpoints.base, data: data);

  Future<Response> updateAdmission(String id, Map<String, dynamic> data) =>
      _client.put(AdmissionEndpoints.byId(id), data: data);

  Future<Response> dischargePatient(String id, Map<String, dynamic> data) =>
      _client.post(AdmissionEndpoints.discharge(id), data: data);

  Future<Response> transferPatient(String id, Map<String, dynamic> data) =>
      _client.post(AdmissionEndpoints.transfer(id), data: data);

  Future<Response> listAdmissions({
    String? patientId,
    String? status,
    String? hospitalId,
    String? departmentId,
    int page = 1,
    int limit = 20,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (patientId != null) params['patient_id'] = patientId;
    if (status != null) params['status'] = status;
    if (hospitalId != null) params['hospital_id'] = hospitalId;
    if (departmentId != null) params['department_id'] = departmentId;
    return _client.get(AdmissionEndpoints.base, queryParameters: params);
  }
}
