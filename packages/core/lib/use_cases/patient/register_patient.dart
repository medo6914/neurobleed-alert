import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/patient_repository.dart';
import '../../security/audit_logger.dart';

class RegisterPatient {
  final PatientRepository _repository;
  final AuditLogger? _auditLogger;

  RegisterPatient(this._repository, [this._auditLogger]);

  Future<Either<Failure, Patient>> call({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required Gender gender,
    String? middleName,
    String? nationality,
    String? nationalId,
    BloodType bloodType = BloodType.unknown,
    double? weight,
    double? height,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    MaritalStatus maritalStatus = MaritalStatus.single,
    String? occupation,
    String? insuranceProvider,
    String? insuranceId,
    List<String>? diagnoses,
    List<String>? allergies,
    List<String>? medications,
    List<String>? comorbidities,
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
    if (firstName.isEmpty) {
      return Left(ValidationFailure(
        message: 'First name is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'firstName': ['First name is required']
        },
      ));
    }
    if (lastName.isEmpty) {
      return Left(ValidationFailure(
        message: 'Last name is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'lastName': ['Last name is required']
        },
      ));
    }
    if (dateOfBirth.isEmpty) {
      return Left(ValidationFailure(
        message: 'Date of birth is required',
        code: 'VALIDATION_ERROR',
        errors: {
          'dateOfBirth': ['Date of birth is required']
        },
      ));
    }
    if (email != null && email.isNotEmpty && !_isValidEmail(email)) {
      return Left(ValidationFailure(
        message: 'Invalid email format',
        code: 'VALIDATION_ERROR',
        errors: {
          'email': ['Invalid email format']
        },
      ));
    }
    if (weight != null && (weight < 0.5 || weight > 500)) {
      return Left(ValidationFailure(
        message: 'Invalid weight value',
        code: 'VALIDATION_ERROR',
        errors: {
          'weight': ['Weight must be between 0.5 and 500 kg']
        },
      ));
    }
    if (height != null && (height < 20 || height > 300)) {
      return Left(ValidationFailure(
        message: 'Invalid height value',
        code: 'VALIDATION_ERROR',
        errors: {
          'height': ['Height must be between 20 and 300 cm']
        },
      ));
    }

    final patient = Patient(
      id: '',
      mrn: '',
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      nationality: nationality,
      nationalId: nationalId,
      bloodType: bloodType,
      weight: weight,
      height: height,
      email: email,
      phone: phone,
      address: address,
      city: city,
      country: country,
      maritalStatus: maritalStatus,
      occupation: occupation,
      insuranceProvider: insuranceProvider,
      insuranceId: insuranceId,
      status: PatientStatus.active,
      hospitalId: hospitalId,
      departmentId: departmentId,
      ward: ward,
      bedNumber: bedNumber,
      primaryDiagnosis: primaryDiagnosis,
      diagnoses: diagnoses ?? [],
      allergies: allergies ?? [],
      medications: medications ?? [],
      comorbidities: comorbidities ?? [],
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: userId,
      updatedBy: userId,
      isDeleted: false,
    );

    final result = await _repository.createPatient(patient);

    result.fold(
      (failure) {},
      (createdPatient) {
        _auditLogger?.logCreate(
          patientId: createdPatient.id,
          resourceType: 'patient',
          resourceId: createdPatient.id,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}
