import 'package:dartz/dartz.dart';
import 'package:shared/entities/medical_document.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/endpoints/documents_endpoints.dart';
import '../database/offline_cache.dart';
import '../sync/sync_queue.dart';

class DocumentsRepository {
  final ApiClient _apiClient;
  final DocumentsApi _documentsApi;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  DocumentsRepository({
    required ApiClient apiClient,
    required DocumentsApi documentsApi,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    OfflineCache? cache,
    SyncQueue? syncQueue,
  })  : _apiClient = apiClient,
        _documentsApi = documentsApi,
        _errorHandler = errorHandler,
        _logger = logger,
        _cache = cache,
        _syncQueue = syncQueue;

  Future<Either<Failure, MedicalDocument>> getDocument(String id) async {
    try {
      final response = await _documentsApi.getDocument(id);
      final document =
          MedicalDocument.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('document_$id', document.toJson());
      return Right(document);
    } catch (e) {
      try {
        final cached = await _cache?.get<MedicalDocument>('document_$id',
            fromJson: (json) =>
                MedicalDocument.fromJson(json as Map<String, dynamic>));
        if (cached != null) return Right(cached);
      } catch (_) {}
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, MedicalDocument>> uploadDocument(
      Map<String, dynamic> data) async {
    try {
      final response = await _documentsApi.createDocument(data);
      final document =
          MedicalDocument.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('document_${document.id}', document.toJson());
      return Right(document);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: data['title'] as String? ?? DateTime.now().toIso8601String(),
          entityType: 'document',
          operation: 'create',
          data: data,
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, MedicalDocument>> updateDocument(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _documentsApi.updateDocument(id, updates);
      final updated =
          MedicalDocument.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('document_$id', updated.toJson());
      return Right(updated);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: id,
          entityType: 'document',
          operation: 'update',
          data: updates,
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteDocument(String id) async {
    try {
      await _documentsApi.deleteDocument(id);
      await _cache?.remove('document_$id');
      return const Right(true);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, MedicalDocument>> verifyDocument(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _documentsApi.verifyDocument(id, data);
      final document =
          MedicalDocument.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('document_$id', document.toJson());
      return Right(document);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, String>> downloadDocument(
      String id, String savePath) async {
    try {
      await _documentsApi.downloadDocument(id, savePath);
      return Right(savePath);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<MedicalDocument>>> listDocuments({
    String? patientId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _documentsApi.listDocuments(
        patientId: patientId,
        type: type,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => MedicalDocument.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
