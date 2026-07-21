import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

class AdmitPatient {
  final AdmissionRepository _admissionRepo;

  AdmitPatient(this._admissionRepo);

  Future<Either<Failure, Admission>> call(Admission admission) async {
    return _admissionRepo.createAdmission(admission);
  }
}

class DischargePatient {
  final AdmissionRepository _admissionRepo;

  DischargePatient(this._admissionRepo);

  Future<Either<Failure, Admission>> call(
    String id, {
    String? dischargeSummary,
    String? dischargeDisposition,
    String? dischargingPhysician,
  }) async {
    return _admissionRepo.dischargePatient(
      id,
      dischargeSummary: dischargeSummary,
      dischargeDisposition: dischargeDisposition,
      dischargingPhysician: dischargingPhysician,
    );
  }
}

final patientAdmissionsProvider = FutureProvider.family<List<Admission>, String>((ref, patientId) async {
  final repository = ref.watch(admissionRepositoryProvider);
  final result = await repository.getPatientAdmissions(patientId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (admissions) => admissions,
  );
});

final admitPatientProvider = Provider<AdmitPatient>((ref) {
  final admissionRepo = ref.watch(admissionRepositoryProvider);
  return AdmitPatient(admissionRepo);
});

final dischargePatientProvider = Provider<DischargePatient>((ref) {
  final admissionRepo = ref.watch(admissionRepositoryProvider);
  return DischargePatient(admissionRepo);
});
