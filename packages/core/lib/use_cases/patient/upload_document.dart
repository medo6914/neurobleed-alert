import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/documents_repository.dart';
import '../../security/audit_logger.dart';

class UploadDocument {
  final DocumentsRepository _repository;
  final AuditLogger? _auditLogger;

  UploadDocument(this._repository, [this._auditLogger]);

  Future<Either<Failure, MedicalDocument>> call({
    required String patientId,
    required DocumentType type,
    required String title,
    required String fileName,
    required String fileUrl,
    int fileSize = 0,
    String? mimeType,
    String? description,
    String? uploadedBy,
    String? uploadedByName,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (title.isEmpty) {
      return Left(ValidationFailure(
          message: 'Document title is required', code: 'VALIDATION_ERROR'));
    }
    if (fileName.isEmpty) {
      return Left(ValidationFailure(
          message: 'File name is required', code: 'VALIDATION_ERROR'));
    }

    final result = await _repository.uploadDocument({
      'patientId': patientId,
      'type': type.name,
      'title': title,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'mimeType': mimeType ?? 'application/octet-stream',
      'description': description,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
    });

    result.fold(
      (failure) {},
      (doc) {
        _auditLogger?.logCreate(
          patientId: patientId,
          resourceType: 'document',
          resourceId: doc.id,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
