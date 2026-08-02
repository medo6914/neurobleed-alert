import 'package:dio/dio.dart';
import '../api_client.dart';

class AnalyticsEndpoints {
  static const String base = '/v1/analytics';
}

class AnalyticsApi {
  final ApiClient _client;

  AnalyticsApi(this._client);

  Future<Response> getOverview({String? hospitalId}) {
    final params = <String, dynamic>{};
    if (hospitalId != null) params['hospital_id'] = hospitalId;
    return _client.get('${AnalyticsEndpoints.base}/overview', queryParameters: params);
  }

  Future<Response> getPatientAnalytics({String? hospitalId}) {
    final params = <String, dynamic>{};
    if (hospitalId != null) params['hospital_id'] = hospitalId;
    return _client.get('${AnalyticsEndpoints.base}/patients', queryParameters: params);
  }

  Future<Response> getDeviceAnalytics({String? hospitalId}) {
    final params = <String, dynamic>{};
    if (hospitalId != null) params['hospital_id'] = hospitalId;
    return _client.get('${AnalyticsEndpoints.base}/devices', queryParameters: params);
  }

  Future<Response> getAlertAnalytics({String? hospitalId}) {
    final params = <String, dynamic>{};
    if (hospitalId != null) params['hospital_id'] = hospitalId;
    return _client.get('${AnalyticsEndpoints.base}/alerts', queryParameters: params);
  }

  Future<Response> getHospitalOverview() =>
      _client.get('${AnalyticsEndpoints.base}/hospitals');

  Future<Response> getSystemHealth() =>
      _client.get('${AnalyticsEndpoints.base}/system-health');

  Future<Response> getActivityFeed({int limit = 50}) =>
      _client.get('${AnalyticsEndpoints.base}/activity-feed', queryParameters: {'limit': limit});
}
