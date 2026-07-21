import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:core/core.dart';
import 'package:shared/shared.dart';
import 'repository_providers.dart';

class RegisterPatient {
  final PatientRepository _repository;

  RegisterPatient(this._repository);

  Future<Either<Failure, Patient>> call(Patient patient) async {
    return _repository.createPatient(patient);
  }
}

final registerPatientProvider = Provider<RegisterPatient>((ref) {
  final repository = ref.watch(patientRepositoryProvider);
  return RegisterPatient(repository);
});
