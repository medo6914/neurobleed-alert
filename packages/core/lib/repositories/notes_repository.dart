import 'package:dartz/dartz.dart';
import 'package:shared/entities/patient_note.dart';
import '../error/failure.dart';
import '../error/error_handler.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../network/endpoints/notes_endpoints.dart';
import '../database/offline_cache.dart';
import '../sync/sync_queue.dart';

class NotesRepository {
  final ApiClient _apiClient;
  final NotesApi _notesApi;
  final ErrorHandler _errorHandler;
  final AppLogger _logger;
  final OfflineCache? _cache;
  final SyncQueue? _syncQueue;

  NotesRepository({
    required ApiClient apiClient,
    required NotesApi notesApi,
    required ErrorHandler errorHandler,
    required AppLogger logger,
    OfflineCache? cache,
    SyncQueue? syncQueue,
  })  : _apiClient = apiClient,
        _notesApi = notesApi,
        _errorHandler = errorHandler,
        _logger = logger,
        _cache = cache,
        _syncQueue = syncQueue;

  Future<Either<Failure, PatientNote>> getNote(String id) async {
    try {
      final response = await _notesApi.getNote(id);
      final note = PatientNote.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('note_$id', note.toJson());
      return Right(note);
    } catch (e) {
      try {
        final cached = await _cache?.get<PatientNote>('note_$id',
            fromJson: (json) =>
                PatientNote.fromJson(json as Map<String, dynamic>));
        if (cached != null) return Right(cached);
      } catch (_) {}
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, PatientNote>> createNote(PatientNote note) async {
    try {
      final response = await _notesApi.createNote(note.toJson());
      final created =
          PatientNote.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('note_${created.id}', created.toJson());
      return Right(created);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: note.id,
          entityType: 'note',
          operation: 'create',
          data: note.toJson(),
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, PatientNote>> updateNote(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _notesApi.updateNote(id, updates);
      final updated =
          PatientNote.fromJson(response.data as Map<String, dynamic>);
      await _cache?.put('note_$id', updated.toJson());
      return Right(updated);
    } catch (e) {
      final sq = _syncQueue;
      if (sq != null && e is NetworkFailure) {
        await sq.add(SyncQueueEntry(
          id: id,
          entityType: 'note',
          operation: 'update',
          data: updates,
          createdAt: DateTime.now(),
        ));
      }
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteNote(String id) async {
    try {
      await _notesApi.deleteNote(id);
      await _cache?.remove('note_$id');
      return const Right(true);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<PatientNote>>> listNotes({
    String? patientId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _notesApi.listNotes(
        patientId: patientId,
        type: type,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => PatientNote.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<PatientNote>>> getPatientNotes(
    String patientId, {
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final response = await _notesApi.listNotes(
        patientId: patientId,
        type: type,
        page: page,
        limit: limit,
      );
      final list = (response.data['data'] as List)
          .map((e) => PatientNote.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(_errorHandler.handle(e));
    }
  }
}
