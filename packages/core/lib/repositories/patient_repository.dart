import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/endpoints/patient_endpoints.dart';
import '../database/offline_cache.dart';
import '../sync/sync_queue.dart';

class PatientRepository {
  final ApiClient _apiClient;
  final PatientApi _patientApi;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  PatientRepository({
    required ApiClient apiClient,
    required PatientApi patientApi,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    OfflineCache? cache,
    SyncQueue? syncQueue,
  })  : _apiClient = apiClient,
        _patientApi = patientApi,
        _errorHandler = errorHandler,
        _logger = logger,
        _cache = cache,
        _syncQueue = syncQueue;

  Future<Either<Failure, Patient>> getPatient(String id) async {
    try {
      final response = await _patientApi.getPatient(id);
      final patient = Patient.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('patient_$id', patient.toJson());
      return Right(patient);
    } catch (e) {
      try {
        final cached = await _cache?.get<Patient>('patient_$id',
            fromJson: (json) => Patient.fromJson(json as Map<String, dynamic>));
        if (cached != null) return Right(cached);
      } catch (_) {}
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Patient>> getPatientByMrn(String mrn) async {
    try {
      final response = await _patientApi.getPatientByMrn(mrn);
      return Right(Patient.fromJson(response.data as Map<String, dynamic>));
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Patient>> createPatient(Patient patient) async {
    try {
      final response = await _patientApi.createPatient(patient.toJson());
      final created = Patient.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('patient_${created.id}', created.toJson());
      return Right(created);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: patient.id,
          entityType: 'patient',
          operation: 'create',
          data: patient.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Patient>> updatePatient(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _patientApi.updatePatient(id, updates);
      final updated = Patient.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('patient_$id', updated.toJson());
      return Right(updated);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: id,
          entityType: 'patient',
          operation: 'update',
          data: updates,
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deletePatient(String id) async {
    try {
      await _patientApi.deletePatient(id);
      await _cache?.remove('patient_$id');
      return const Right(true);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Patient>>> searchPatients({
    String? query,
    String? status,
    String? hospitalId,
    String? departmentId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _patientApi.searchPatients(
        query: query,
        status: status,
        hospitalId: hospitalId,
        departmentId: departmentId,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Patient>>> listPatients({
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await _patientApi.listPatients(
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      final list = (response.data['data'] as List)
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, int>> getTotalCount({String? hospitalId}) async {
    try {
      final params = <String, dynamic>{'page': 1, 'limit': 1};
      if (hospitalId != null) params['hospital_id'] = hospitalId;
      final response =
          await _apiClient.get('/v1/patients', queryParameters: params);
      final total = response.data['total'] as int? ?? 0;
      return Right(total);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
