import 'package:dio/dio.dart';
import '../api_client.dart';

class AIEndpoints {
  static const String base = '/v1/ai';
  static const String riskAssess = '/v1/ai/risk/assess';
  static const String riskBatch = '/v1/ai/risk/batch';
  static String riskHistory(String patientId) => '/v1/ai/risk/history/$patientId';
  static const String knowledgeSearch = '/v1/ai/knowledge/search';
  static const String health = '/v1/ai/health';
}

class AIApi {
  final ApiClient _client;

  AIApi(this._client);

  Future<Response> assessRisk(Map<String, dynamic> data) =>
      _client.post(AIEndpoints.riskAssess, data: data);

  Future<Response> batchAssess(Map<String, dynamic> data) =>
      _client.post(AIEndpoints.riskBatch, data: data);

  Future<Response> getRiskHistory(String patientId, {int limit = 50}) =>
      _client.get(AIEndpoints.riskHistory(patientId), queryParameters: {'limit': limit});

  Future<Response> searchKnowledge(Map<String, dynamic> data) =>
      _client.post(AIEndpoints.knowledgeSearch, data: data);

  Future<Response> health() =>
      _client.get(AIEndpoints.health);
}
