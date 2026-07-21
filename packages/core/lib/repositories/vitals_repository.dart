import 'package:dartz/dartz.dart';
import 'package:shared/entities/vitals_record.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/endpoints/vitals_endpoints.dart';
import '../database/offline_cache.dart';
import '../sync/sync_queue.dart';

class VitalsRepository {
  final ApiClient _apiClient;
  final VitalsApi _vitalsApi;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  VitalsRepository({
    required ApiClient apiClient,
    required VitalsApi vitalsApi,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    OfflineCache? cache,
    SyncQueue? syncQueue,
  })  : _apiClient = apiClient,
        _vitalsApi = vitalsApi,
        _errorHandler = errorHandler,
        _logger = logger,
        _cache = cache,
        _syncQueue = syncQueue;

  Future<Either<Failure, VitalsRecord>> getVital(String id) async {
    try {
      final response = await _vitalsApi.getVital(id);
      final vital =
          VitalsRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('vital_$id', vital.toJson());
      return Right(vital);
    } catch (e) {
      try {
        final cached = await _cache?.get<VitalsRecord>('vital_$id',
            fromJson: (json) =>
                VitalsRecord.fromJson(json as Map<String, dynamic>));
        if (cached != null) return Right(cached);
      } catch (_) {}
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, VitalsRecord>> createVital(VitalsRecord vital) async {
    try {
      final response = await _vitalsApi.createVital(vital.toJson());
      final created =
          VitalsRecord.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('vital_${created.id}', created.toJson());
      return Right(created);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: vital.id,
          entityType: 'vital',
          operation: 'create',
          data: vital.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<VitalsRecord>>> createBatch(
      List<VitalsRecord> vitals) async {
    try {
      final vitalsJson = vitals.map((v) => v.toJson()).toList();
      final response = await _vitalsApi.createBatch(vitalsJson);
      final list = (response.data['data'] as List)
          .map((e) => VitalsRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        for (final vital in vitals) {
          await sq.add(SyncQueueEntry(
            id: vital.id,
            entityType: 'vital',
            operation: 'create',
            data: vital.toJson(),
            createdAt: DateTime.now(),
          ));
        }
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, VitalsRecord>> getLatestVitals(
      String patientId) async {
    try {
      final response = await _vitalsApi.getLatestVitals(patientId);
      return Right(
          VitalsRecord.fromJson(response.data as Map<String, dynamic>));
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<VitalsRecord>>> getVitalsRange(
    String patientId, {
    required DateTime from,
    required DateTime to,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _vitalsApi.getVitalsRange(
        patientId,
        from: from,
        to: to,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => VitalsRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<VitalsRecord>>> listVitals({
    String? patientId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _vitalsApi.listVitals(
        patientId: patientId,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => VitalsRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
