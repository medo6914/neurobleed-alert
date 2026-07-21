import 'package:dartz/dartz.dart';
import 'package:shared/entities/admission.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/endpoints/admission_endpoints.dart';
import '../database/offline_cache.dart';
import '../sync/sync_queue.dart';

class AdmissionRepository {
  final ApiClient _apiClient;
  final AdmissionApi _admissionApi;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  AdmissionRepository({
    required ApiClient apiClient,
    required AdmissionApi admissionApi,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    OfflineCache? cache,
    SyncQueue? syncQueue,
  })  : _apiClient = apiClient,
        _admissionApi = admissionApi,
        _errorHandler = errorHandler,
        _logger = logger,
        _cache = cache,
        _syncQueue = syncQueue;

  Future<Either<Failure, Admission>> getAdmission(String id) async {
    try {
      final response = await _admissionApi.getAdmission(id);
      final admission =
          Admission.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('admission_$id', admission.toJson());
      return Right(admission);
    } catch (e) {
      try {
        final cached = await _cache?.get<Admission>('admission_$id',
            fromJson: (json) =>
                Admission.fromJson(json as Map<String, dynamic>));
        if (cached != null) return Right(cached);
      } catch (_) {}
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Admission>> createAdmission(
      Admission admission) async {
    try {
      final response = await _admissionApi.createAdmission(admission.toJson());
      final created = Admission.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('admission_${created.id}', created.toJson());
      return Right(created);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: admission.id,
          entityType: 'admission',
          operation: 'create',
          data: admission.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Admission>> updateAdmission(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _admissionApi.updateAdmission(id, updates);
      final updated = Admission.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('admission_$id', updated.toJson());
      return Right(updated);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: id,
          entityType: 'admission',
          operation: 'update',
          data: updates,
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Admission>> dischargePatient(
    String id, {
    String? dischargeSummary,
    String? dischargeDisposition,
    String? dischargingPhysician,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (dischargeSummary != null)
        data['discharge_summary'] = dischargeSummary;
      if (dischargeDisposition != null)
        data['discharge_disposition'] = dischargeDisposition;
      if (dischargingPhysician != null)
        data['discharging_physician'] = dischargingPhysician;
      final response = await _admissionApi.dischargePatient(id, data);
      final admission =
          Admission.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('admission_$id', admission.toJson());
      return Right(admission);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, Admission>> transferPatient(
    String id, {
    String? hospitalId,
    String? departmentId,
    String? ward,
    String? bedNumber,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (hospitalId != null) data['hospital_id'] = hospitalId;
      if (departmentId != null) data['department_id'] = departmentId;
      if (ward != null) data['ward'] = ward;
      if (bedNumber != null) data['bed_number'] = bedNumber;
      final response = await _admissionApi.transferPatient(id, data);
      final admission =
          Admission.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('admission_$id', admission.toJson());
      return Right(admission);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Admission>>> listAdmissions({
    String? patientId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _admissionApi.listAdmissions(
        patientId: patientId,
        status: status,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => Admission.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Admission>>> getPatientAdmissions(
    String patientId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _admissionApi.listAdmissions(
        patientId: patientId,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => Admission.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
