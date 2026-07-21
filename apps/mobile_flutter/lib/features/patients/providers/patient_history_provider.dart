import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

class PatientHistoryData {
  final Patient patient;
  final List<Admission> admissions;
  final List<PatientNote> notes;
  final List<VitalsRecord> vitals;
  final List<AlertRecord> alerts;

  const PatientHistoryData({
    required this.patient,
    this.admissions = const [],
    this.notes = const [],
    this.vitals = const [],
    this.alerts = const [],
  });
}

class GetPatientHistory {
  final PatientRepository _patientRepo;
  final AdmissionRepository _admissionRepo;
  final NotesRepository _notesRepo;
  final VitalsRepository _vitalsRepo;
  final AlertRepository _alertRepo;

  GetPatientHistory(
    this._patientRepo,
    this._admissionRepo,
    this._notesRepo,
    this._vitalsRepo,
    this._alertRepo,
  );

  Future<Either<Failure, PatientHistoryData>> call(String patientId) async {
    final results = await Future.wait([
      _patientRepo.getPatient(patientId),
      _admissionRepo.getPatientAdmissions(patientId),
      _notesRepo.getPatientNotes(patientId),
      _vitalsRepo.listVitals(patientId: patientId),
      _alertRepo.getPatientAlerts(patientId),
    ]);

    final patientResult = results[0] as Either<Failure, Patient>;
    return patientResult.fold(
      (failure) => Left(failure),
      (patient) {
        final admissions = (results[1] as Either<Failure, List<Admission>>)
            .fold((_) => <Admission>[], (data) => data);
        final notes = (results[2] as Either<Failure, List<PatientNote>>)
            .fold((_) => <PatientNote>[], (data) => data);
        final vitals = (results[3] as Either<Failure, List<VitalsRecord>>)
            .fold((_) => <VitalsRecord>[], (data) => data);
        final alerts = (results[4] as Either<Failure, List<AlertRecord>>)
            .fold((_) => <AlertRecord>[], (data) => data);

        return Right(PatientHistoryData(
          patient: patient,
          admissions: admissions,
          notes: notes,
          vitals: vitals,
          alerts: alerts,
        ));
      },
    );
  }
}

final getPatientHistoryProvider = Provider<GetPatientHistory>((ref) {
  return GetPatientHistory(
    ref.watch(patientRepositoryProvider),
    ref.watch(admissionRepositoryProvider),
    ref.watch(notesRepositoryProvider),
    ref.watch(vitalsRepositoryProvider),
    ref.watch(alertRepositoryProvider),
  );
});

final patientHistoryProvider = FutureProvider.family<PatientHistoryData, String>((ref, patientId) async {
  final useCase = ref.watch(getPatientHistoryProvider);
  final result = await useCase(patientId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});
