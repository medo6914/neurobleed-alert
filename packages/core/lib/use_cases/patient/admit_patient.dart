import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/admission_repository.dart';
import '../../repositories/patient_repository.dart';
import '../../security/audit_logger.dart';

class AdmitPatient {
  final AdmissionRepository _admissionRepo;
  final PatientRepository _patientRepo;
  final AuditLogger? _auditLogger;

  AdmitPatient(this._admissionRepo, this._patientRepo, [this._auditLogger]);

  Future<Either<Failure, Admission>> call({
    required String patientId,
    required String admissionType,
    required String admittingPhysician,
    String? hospitalId,
    String? departmentId,
    String? ward,
    String? bedNumber,
    String? primaryDiagnosis,
    String? notes,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    final patientResult = await _patientRepo.getPatient(patientId);
    if (patientResult.isLeft()) {
      return patientResult.fold(
        (failure) => Left(failure),
        (_) => const Left(ServerFailure(message: 'Patient not found')),
      );
    }

    final admission = Admission(
      id: '',
      patientId: patientId,
      patientName: '',
      hospitalId: hospitalId,
      departmentId: departmentId,
      ward: ward,
      bedNumber: bedNumber,
      status: AdmissionStatus.active,
      admissionType: admissionType,
      admissionDate: DateTime.now(),
      admittingPhysician: admittingPhysician,
      admittingPhysicianId: userId,
      primaryDiagnosis: primaryDiagnosis,
      admissionNotes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _admissionRepo.createAdmission(admission);

    result.fold(
      (failure) {},
      (createdAdmission) {
        _auditLogger?.log(
          patientId: patientId,
          userId: userId,
          userName: userName,
          userRole: userRole,
          action: 'create',
          resourceType: 'admission',
          resourceId: createdAdmission.id,
          details: 'Patient admitted: $admissionType',
        );
      },
    );

    return result;
  }
}
