import 'package:dartz/dartz.dart';
import 'package:shared/entities/audit_record.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/endpoints/patient_endpoints.dart';
import '../database/offline_cache.dart';
import '../sync/sync_queue.dart';

class AuditRepository {
  final ApiClient _apiClient;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  AuditRepository({
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

  Future<Either<Failure, List<AuditRecord>>> getAuditLog(
    String patientId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        PatientEndpoints.audit(patientId),
        queryParameters: {'page': page, 'limit': limit},
      );
      final list = (response.data['data'] as List)
          .map((e) => AuditRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, AuditRecord>> createAuditLog(
      AuditRecord record) async {
    try {
      final response =
          await _apiClient.post('/v1/audit', data: record.toJson());
      final created =
          AuditRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('audit_${created.id}', created.toJson());
      return Right(created);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: record.id,
          entityType: 'audit',
          operation: 'create',
          data: record.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<AuditRecord>>> getResourceAuditLog(
    String resourceType,
    String resourceId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/v1/audit/resource/$resourceType/$resourceId',
        queryParameters: {'page': page, 'limit': limit},
      );
      final list = (response.data['data'] as List)
          .map((e) => AuditRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
