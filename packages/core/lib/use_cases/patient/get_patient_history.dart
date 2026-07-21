import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/patient_repository.dart';
import '../../repositories/admission_repository.dart';
import '../../repositories/notes_repository.dart';
import '../../repositories/vitals_repository.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/audit_repository.dart';

class PatientHistoryData {
  final Patient patient;
  final List<Admission> admissions;
  final List<PatientNote> recentNotes;
  final List<VitalsRecord> recentVitals;
  final List<AlertRecord> recentAlerts;

  const PatientHistoryData({
    required this.patient,
    this.admissions = const [],
    this.recentNotes = const [],
    this.recentVitals = const [],
    this.recentAlerts = const [],
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
    final patientResult = await _patientRepo.getPatient(patientId);
    if (patientResult.isLeft()) {
      return patientResult.fold(
        (failure) => Left(failure),
        (_) => const Left(ServerFailure(message: 'Unexpected error')),
      );
    }

    final patient =
        patientResult.getOrElse(() => throw StateError('Unreachable'));

    final admissionsResult =
        await _admissionRepo.getPatientAdmissions(patientId, limit: 5);
    final notesResult = await _notesRepo.getPatientNotes(patientId, limit: 5);
    final vitalsResult =
        await _vitalsRepo.listVitals(patientId: patientId, limit: 10);
    final alertsResult =
        await _alertRepo.getPatientAlerts(patientId, limit: 10);

    return Right(PatientHistoryData(
      patient: patient,
      admissions: admissionsResult.getOrElse(() => <Admission>[]),
      recentNotes: notesResult.getOrElse(() => <PatientNote>[]),
      recentVitals: vitalsResult.getOrElse(() => <VitalsRecord>[]),
      recentAlerts: alertsResult.getOrElse(() => <AlertRecord>[]),
    ));
  }
}
