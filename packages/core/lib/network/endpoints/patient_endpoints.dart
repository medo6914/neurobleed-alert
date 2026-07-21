import 'package:dio/dio.dart';
import 'package:shared/shared.dart';
import '../api_client.dart';

class PatientEndpoints {
  static const String base = '/v1/patients';
  static const String search = '/v1/patients/search';
  static const String batch = '/v1/patients/batch';
  static const String merge = '/v1/patients/merge';
  static const String archive = '/v1/patients/archive';
  static const String restore = '/v1/patients/restore';
  static String byId(String id) => '/v1/patients/$id';
  static String byMrn(String mrn) => '/v1/patients/mrn/$mrn';
  static String admissions(String patientId) =>
      '/v1/patients/$patientId/admissions';
  static String notes(String patientId) => '/v1/patients/$patientId/notes';
  static String documents(String patientId) =>
      '/v1/patients/$patientId/documents';
  static String timeline(String patientId) =>
      '/v1/patients/$patientId/timeline';
  static String vitals(String patientId) => '/v1/patients/$patientId/vitals';
  static String alerts(String patientId) => '/v1/patients/$patientId/alerts';
  static String risks(String patientId) => '/v1/patients/$patientId/risks';
  static String audit(String patientId) => '/v1/patients/$patientId/audit';
  static String emergencyContacts(String patientId) =>
      '/v1/patients/$patientId/emergency-contacts';
  static String assignments(String patientId) =>
      '/v1/patients/$patientId/assignments';
}

class PatientApi {
  final ApiClient _client;

  PatientApi(this._client);

  // ===== CRUD =====

  Future<Response> getPatient(String id) =>
      _client.get(PatientEndpoints.byId(id));

  Future<Response> getPatientByMrn(String mrn) =>
      _client.get(PatientEndpoints.byMrn(mrn));

  Future<Response> createPatient(Map<String, dynamic> data) =>
      _client.post(PatientEndpoints.base, data: data);

  Future<Response> updatePatient(String id, Map<String, dynamic> data) =>
      _client.put(PatientEndpoints.byId(id), data: data);

  Future<Response> patchPatient(String id, Map<String, dynamic> data) =>
      _client.patch(PatientEndpoints.byId(id), data: data);

  Future<Response> deletePatient(String id) =>
      _client.delete(PatientEndpoints.byId(id));

  // ===== Search =====

  Future<Response> searchPatients({
    String? query,
    String? status,
    String? hospitalId,
    String? departmentId,
    String? ward,
    String? gender,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (query != null) params['q'] = query;
    if (status != null) params['status'] = status;
    if (hospitalId != null) params['hospital_id'] = hospitalId;
    if (departmentId != null) params['department_id'] = departmentId;
    if (ward != null) params['ward'] = ward;
    if (gender != null) params['gender'] = gender;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    return _client.get(PatientEndpoints.search, queryParameters: params);
  }

  Future<Response> listPatients({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    return _client.get(PatientEndpoints.base, queryParameters: params);
  }

  // ===== Batch Operations =====

  Future<Response> batchCreate(List<Map<String, dynamic>> patients) =>
      _client.post(PatientEndpoints.batch, data: {'patients': patients});

  Future<Response> mergePatients(String primaryId, List<String> duplicateIds) =>
      _client.post(PatientEndpoints.merge, data: {
        'primary_id': primaryId,
        'duplicate_ids': duplicateIds,
      });

  // ===== Archive / Restore =====

  Future<Response> archivePatient(String id) =>
      _client.post(PatientEndpoints.archive, data: {'id': id});

  Future<Response> restorePatient(String id) =>
      _client.post(PatientEndpoints.restore, data: {'id': id});

  // ===== Related Resources =====

  Future<Response> getAdmissions(String patientId,
          {int page = 1, int limit = 20}) =>
      _client.get(PatientEndpoints.admissions(patientId),
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> getNotes(String patientId,
      {int page = 1, int limit = 20, String? type}) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
    return _client.get(PatientEndpoints.notes(patientId),
        queryParameters: params);
  }

  Future<Response> getDocuments(String patientId,
          {int page = 1, int limit = 20}) =>
      _client.get(PatientEndpoints.documents(patientId),
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> getTimeline(String patientId,
          {int page = 1, int limit = 50}) =>
      _client.get(PatientEndpoints.timeline(patientId),
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> getVitals(String patientId,
      {int page = 1, int limit = 50, String? from, String? to}) {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    return _client.get(PatientEndpoints.vitals(patientId),
        queryParameters: params);
  }

  Future<Response> getAlerts(String patientId,
          {int page = 1, int limit = 20}) =>
      _client.get(PatientEndpoints.alerts(patientId),
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> getRisks(String patientId, {int page = 1, int limit = 20}) =>
      _client.get(PatientEndpoints.risks(patientId),
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> getAuditLog(String patientId,
          {int page = 1, int limit = 20}) =>
      _client.get(PatientEndpoints.audit(patientId),
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> getEmergencyContacts(String patientId) =>
      _client.get(PatientEndpoints.emergencyContacts(patientId));

  Future<Response> createEmergencyContact(
          String patientId, Map<String, dynamic> data) =>
      _client.post(PatientEndpoints.emergencyContacts(patientId), data: data);

  Future<Response> updateEmergencyContact(
          String patientId, String contactId, Map<String, dynamic> data) =>
      _client.put('${PatientEndpoints.emergencyContacts(patientId)}/$contactId',
          data: data);

  Future<Response> deleteEmergencyContact(String patientId, String contactId) =>
      _client.delete(
          '${PatientEndpoints.emergencyContacts(patientId)}/$contactId');

  Future<Response> getAssignments(String patientId) =>
      _client.get(PatientEndpoints.assignments(patientId));

  Future<Response> createAssignment(
          String patientId, Map<String, dynamic> data) =>
      _client.post(PatientEndpoints.assignments(patientId), data: data);

  Future<Response> updateAssignment(
          String patientId, String assignmentId, Map<String, dynamic> data) =>
      _client.put('${PatientEndpoints.assignments(patientId)}/$assignmentId',
          data: data);
}
