import 'package:dartz/dartz.dart';
import 'package:shared/entities/alert_record.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/endpoints/patient_endpoints.dart';
import '../database/offline_cache.dart';
import '../sync/sync_queue.dart';

class AlertRepository {
  final ApiClient _apiClient;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  AlertRepository({
    required ApiClient apiClient,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    OfflineCache? cache,
    SyncQueue? syncQueue,
  })  : _apiClient = apiClient,
        _errorHandler = errorHandler,
        _logger = logger,
        _cache = cache,
        _syncQueue = syncQueue;

  Future<Either<Failure, AlertRecord>> getAlert(String id) async {
    try {
      final response = await _apiClient.get('/v1/alerts/$id');
      final alert = AlertRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('alert_$id', alert.toJson());
      return Right(alert);
    } catch (e) {
      try {
        final cached = await _cache?.get<AlertRecord>('alert_$id',
            fromJson: (json) =>
                AlertRecord.fromJson(json as Map<String, dynamic>));
        if (cached != null) return Right(cached);
      } catch (_) {}
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, AlertRecord>> createAlert(AlertRecord alert) async {
    try {
      final response =
          await _apiClient.post('/v1/alerts', data: alert.toJson());
      final created =
          AlertRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('alert_${created.id}', created.toJson());
      return Right(created);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: alert.id,
          entityType: 'alert',
          operation: 'create',
          data: alert.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, AlertRecord>> updateAlert(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.put('/v1/alerts/$id', data: updates);
      final updated =
          AlertRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('alert_$id', updated.toJson());
      return Right(updated);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: id,
          entityType: 'alert',
          operation: 'update',
          data: updates,
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, AlertRecord>> acknowledgeAlert(String id,
      {String? acknowledgedBy}) async {
    try {
      final data = <String, dynamic>{};
      if (acknowledgedBy != null) data['acknowledged_by'] = acknowledgedBy;
      final response =
          await _apiClient.post('/v1/alerts/$id/acknowledge', data: data);
      final alert = AlertRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('alert_$id', alert.toJson());
      return Right(alert);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, AlertRecord>> resolveAlert(String id,
      {String? resolvedBy}) async {
    try {
      final data = <String, dynamic>{};
      if (resolvedBy != null) data['resolved_by'] = resolvedBy;
      final response =
          await _apiClient.post('/v1/alerts/$id/resolve', data: data);
      final alert = AlertRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('alert_$id', alert.toJson());
      return Right(alert);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, AlertRecord>> escalateAlert(
    String id, {
    String? escalationLevel,
    String? escalationNotes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (escalationLevel != null) data['escalation_level'] = escalationLevel;
      if (escalationNotes != null) data['escalation_notes'] = escalationNotes;
      final response =
          await _apiClient.post('/v1/alerts/$id/escalate', data: data);
      final alert = AlertRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('alert_$id', alert.toJson());
      return Right(alert);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<AlertRecord>>> listAlerts({
    String? patientId,
    String? status,
    String? level,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (patientId != null) params['patient_id'] = patientId;
      if (status != null) params['status'] = status;
      if (level != null) params['level'] = level;
      final response =
          await _apiClient.get('/v1/alerts', queryParameters: params);
      final list = (response.data['data'] as List)
          .map((e) => AlertRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<AlertRecord>>> getPatientAlerts(
    String patientId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        PatientEndpoints.alerts(patientId),
        queryParameters: {'page': page, 'limit': limit},
      );
      final list = (response.data['data'] as List)
          .map((e) => AlertRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
