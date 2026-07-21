import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/admission_repository.dart';
import '../../security/audit_logger.dart';

class DischargePatient {
  final AdmissionRepository _admissionRepo;
  final AuditLogger? _auditLogger;

  DischargePatient(this._admissionRepo, [this._auditLogger]);

  Future<Either<Failure, Admission>> call({
    required String admissionId,
    required String dischargeSummary,
    required String dischargeDisposition,
    String? dischargingPhysician,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    if (dischargeSummary.isEmpty) {
      return Left(ValidationFailure(
        message: 'Discharge summary is required',
        code: 'VALIDATION_ERROR',
      ));
    }

    if (dischargeDisposition.isEmpty) {
      return Left(ValidationFailure(
        message: 'Discharge disposition is required',
        code: 'VALIDATION_ERROR',
      ));
    }

    final result = await _admissionRepo.dischargePatient(
      admissionId,
      dischargeSummary: dischargeSummary,
      dischargeDisposition: dischargeDisposition,
      dischargingPhysician: dischargingPhysician,
    );

    result.fold(
      (failure) {},
      (discharged) {
        _auditLogger?.log(
          patientId: discharged.patientId,
          userId: userId,
          userName: userName,
          userRole: userRole,
          action: 'update',
          resourceType: 'admission',
          resourceId: admissionId,
          details: 'Patient discharged: $dischargeDisposition',
        );
      },
    );

    return result;
  }
}
