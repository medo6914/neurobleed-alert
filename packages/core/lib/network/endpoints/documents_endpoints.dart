import 'package:dio/dio.dart';
import '../api_client.dart';

class DocumentsEndpoints {
  static const String base = '/v1/documents';
  static String byId(String id) => '/v1/documents/$id';
  static String download(String id) => '/v1/documents/$id/download';
  static String verify(String id) => '/v1/documents/$id/verify';
}

class DocumentsApi {
  final ApiClient _client;

  DocumentsApi(this._client);

  Future<Response> getDocument(String id) =>
      _client.get(DocumentsEndpoints.byId(id));

  Future<Response> createDocument(Map<String, dynamic> data) =>
      _client.post(DocumentsEndpoints.base, data: data);

  Future<Response> updateDocument(String id, Map<String, dynamic> data) =>
      _client.put(DocumentsEndpoints.byId(id), data: data);

  Future<Response> deleteDocument(String id) =>
      _client.delete(DocumentsEndpoints.byId(id));

  Future<Response> verifyDocument(String id, Map<String, dynamic> data) =>
      _client.post(DocumentsEndpoints.verify(id), data: data);

  Future<Response> downloadDocument(String id, String savePath) =>
      _client.download(DocumentsEndpoints.download(id), savePath);

  Future<Response> listDocuments({
    String? patientId,
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (patientId != null) params['patient_id'] = patientId;
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    return _client.get(DocumentsEndpoints.base, queryParameters: params);
  }
}
