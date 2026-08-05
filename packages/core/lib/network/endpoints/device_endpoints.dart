import 'package:dio/dio.dart';
import '../api_client.dart';

class DeviceEndpoints {
  static const String base = '/v1/devices';
  static const String bulk = '/v1/devices/bulk';
  static const String diagnostics = '/v1/devices/diagnostics';
  static String byId(String id) => '/v1/devices/$id';
  static String status(String id) => '/v1/devices/$id/status';
  static String heartbeat(String id) => '/v1/devices/$id/heartbeat';
  static String assign(String id) => '/v1/devices/$id/assign';
  static String unassign(String id) => '/v1/devices/$id/unassign';
  static String deviceDiagnostics(String id) => '/v1/devices/$id/diagnostics';
  static String ota(String id) => '/v1/devices/$id/ota';
  static String certificate(String id) => '/v1/devices/$id/certificate';
  static String history(String id) => '/v1/devices/$id/history';
}

class DeviceApi {
  final ApiClient _client;

  DeviceApi(this._client);

  Future<Response> registerDevice(Map<String, dynamic> data) =>
      _client.post(DeviceEndpoints.base, data: data);

  Future<Response> listDevices({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    String? status,
    String? deviceType,
    String? hospitalId,
    String? patientId,
    String? search,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    if (status != null) params['status'] = status;
    if (deviceType != null) params['device_type'] = deviceType;
    if (hospitalId != null) params['hospital_id'] = hospitalId;
    if (patientId != null) params['patient_id'] = patientId;
    if (search != null) params['q'] = search;
    return _client.get(DeviceEndpoints.base, queryParameters: params);
  }

  Future<Response> getDevice(String id) =>
      _client.get(DeviceEndpoints.byId(id));

  Future<Response> updateDevice(String id, Map<String, dynamic> data) =>
      _client.put(DeviceEndpoints.byId(id), data: data);

  Future<Response> deleteDevice(String id) =>
      _client.delete(DeviceEndpoints.byId(id));

  Future<Response> updateStatus(String id, Map<String, dynamic> data) =>
      _client.patch(DeviceEndpoints.status(id), data: data);

  Future<Response> heartbeat(String id, Map<String, dynamic> data) =>
      _client.post(DeviceEndpoints.heartbeat(id), data: data);

  Future<Response> assignDevice(String id, Map<String, dynamic> data) =>
      _client.post(DeviceEndpoints.assign(id), data: data);

  Future<Response> unassignDevice(String id) =>
      _client.post(DeviceEndpoints.unassign(id));

  Future<Response> getDiagnostics(String id) =>
      _client.get(DeviceEndpoints.deviceDiagnostics(id));

  Future<Response> bulkOperation(Map<String, dynamic> data) =>
      _client.post(DeviceEndpoints.bulk, data: data);

  Future<Response> triggerOta(String id, Map<String, dynamic> data) =>
      _client.post(DeviceEndpoints.ota(id), data: data);

  Future<Response> registerCertificate(String id, Map<String, dynamic> data) =>
      _client.post(DeviceEndpoints.certificate(id), data: data);

  Future<Response> getHistory(
    String id, {
    int page = 1,
    int limit = 20,
  }) =>
      _client.get(DeviceEndpoints.history(id),
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> generateProvisioningKey(Map<String, dynamic> data) =>
      _client.post('${DeviceEndpoints.base}/provisioning/keys', data: data);

  Future<Response> listProvisioningKeys({
    int page = 1,
    int limit = 20,
    String? status,
    String? deviceType,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null) params['status'] = status;
    if (deviceType != null) params['device_type'] = deviceType;
    return _client.get('${DeviceEndpoints.base}/provisioning/keys',
        queryParameters: params);
  }

  Future<Response> getProvisioningKey(String keyId) =>
      _client.get('${DeviceEndpoints.base}/provisioning/keys/$keyId');

  Future<Response> revokeProvisioningKey(String keyId) =>
      _client.post('${DeviceEndpoints.base}/provisioning/keys/$keyId/revoke');

  Future<Response> claimDevice(Map<String, dynamic> data) =>
      _client.post('${DeviceEndpoints.base}/provisioning/claim', data: data);

  Future<Response> logDiagnostics(String id, Map<String, dynamic> data) =>
      _client.post('${DeviceEndpoints.base}/$id/diagnostics/log', data: data);

  Future<Response> listDiagnosticsLogs(String id,
          {int page = 1, int limit = 50}) =>
      _client.get('${DeviceEndpoints.base}/$id/diagnostics/logs',
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> listDeviceEvents(String id,
      {String? eventType, int limit = 50}) {
    final params = <String, dynamic>{'limit': limit};
    if (eventType != null) params['event_type'] = eventType;
    return _client.get('${DeviceEndpoints.base}/$id/events',
        queryParameters: params);
  }
}
