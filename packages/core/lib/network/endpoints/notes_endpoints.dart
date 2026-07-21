import 'package:dio/dio.dart';
import '../api_client.dart';

class NotesEndpoints {
  static const String base = '/v1/notes';
  static String byId(String id) => '/v1/notes/$id';
}

class NotesApi {
  final ApiClient _client;

  NotesApi(this._client);

  Future<Response> getNote(String id) => _client.get(NotesEndpoints.byId(id));

  Future<Response> createNote(Map<String, dynamic> data) =>
      _client.post(NotesEndpoints.base, data: data);

  Future<Response> updateNote(String id, Map<String, dynamic> data) =>
      _client.put(NotesEndpoints.byId(id), data: data);

  Future<Response> deleteNote(String id) =>
      _client.delete(NotesEndpoints.byId(id));

  Future<Response> listNotes({
    String? patientId,
    String? type,
    String? authorId,
    int page = 1,
    int limit = 20,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (patientId != null) params['patient_id'] = patientId;
    if (type != null) params['type'] = type;
    if (authorId != null) params['author_id'] = authorId;
    return _client.get(NotesEndpoints.base, queryParameters: params);
  }
}
