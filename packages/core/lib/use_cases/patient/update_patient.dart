import 'package:dartz/dartz.dart';
import 'package:shared/shared.dart';
import '../../error/failure.dart';
import '../../repositories/patient_repository.dart';
import '../../security/audit_logger.dart';

class UpdatePatient {
  final PatientRepository _repository;
  final AuditLogger? _auditLogger;

  UpdatePatient(this._repository, [this._auditLogger]);

  Future<Either<Failure, Patient>> call({
    required String id,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    Gender? gender,
    String? nationality,
    String? nationalId,
    BloodType? bloodType,
    double? weight,
    double? height,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    MaritalStatus? maritalStatus,
    String? occupation,
    String? insuranceProvider,
    String? insuranceId,
    String? hospitalId,
    String? departmentId,
    String? ward,
    String? bedNumber,
    String? primaryDiagnosis,
    List<String>? diagnoses,
    List<String>? allergies,
    List<String>? medications,
    List<String>? comorbidities,
    String? notes,
    String? userId,
    String? userName,
    String? userRole,
  }) async {
    final updates = <String, dynamic>{};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (dateOfBirth != null) updates['dateOfBirth'] = dateOfBirth;
    if (gender != null) updates['gender'] = gender.name;
    if (nationality != null) updates['nationality'] = nationality;
    if (nationalId != null) updates['nationalId'] = nationalId;
    if (bloodType != null) updates['bloodType'] = bloodType.name;
    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;
    if (email != null) updates['email'] = email;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (city != null) updates['city'] = city;
    if (country != null) updates['country'] = country;
    if (maritalStatus != null) updates['maritalStatus'] = maritalStatus.name;
    if (occupation != null) updates['occupation'] = occupation;
    if (insuranceProvider != null)
      updates['insuranceProvider'] = insuranceProvider;
    if (insuranceId != null) updates['insuranceId'] = insuranceId;
    if (hospitalId != null) updates['hospitalId'] = hospitalId;
    if (departmentId != null) updates['departmentId'] = departmentId;
    if (ward != null) updates['ward'] = ward;
    if (bedNumber != null) updates['bedNumber'] = bedNumber;
    if (primaryDiagnosis != null)
      updates['primaryDiagnosis'] = primaryDiagnosis;
    if (diagnoses != null) updates['diagnoses'] = diagnoses;
    if (allergies != null) updates['allergies'] = allergies;
    if (medications != null) updates['medications'] = medications;
    if (comorbidities != null) updates['comorbidities'] = comorbidities;
    if (notes != null) updates['notes'] = notes;

    final result = await _repository.updatePatient(id, updates);

    result.fold(
      (failure) {},
      (updatedPatient) {
        _auditLogger?.logUpdate(
          patientId: id,
          resourceType: 'patient',
          resourceId: id,
          changes: updates,
          userId: userId,
          userName: userName,
          userRole: userRole,
        );
      },
    );

    return result;
  }
}
