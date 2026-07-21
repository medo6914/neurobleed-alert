import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/notes_repository.dart';
import '../../security/audit_logger.dart';

class AddPatientNote {
  final NotesRepository _repository;
  final AuditLogger? _auditLogger;

  AddPatientNote(this._repository, [this._auditLogger]);

  Future<Either<Failure, PatientNote>> call({
    required String patientId,
    required NoteType type,
    required String title,
    required String content,
    List<String> tags = const [],
    bool isConfidential = false,
    bool isSticky = false,
    String? authorId,
    String? authorName,
    String? authorRole,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (title.isEmpty) {
      return Left(ValidationFailure(
        message: 'Note title is required',
        code: 'VALIDATION_ERROR',
      ));
    }
    if (content.isEmpty) {
      return Left(ValidationFailure(
        message: 'Note content is required',
        code: 'VALIDATION_ERROR',
      ));
    }

    final note = PatientNote(
      id: '',
      patientId: patientId,
      type: type,
      status: NoteStatus.final_,
      title: title,
      content: content,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      tags: tags,
      isConfidential: isConfidential,
      isSticky: isSticky,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _repository.createNote(note);

    result.fold(
      (failure) {},
      (createdNote) {
        _auditLogger?.logCreate(
          patientId: patientId,
          resourceType: 'note',
          resourceId: createdNote.id,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
