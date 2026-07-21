import 'package:shared/shared.dart';
import 'fhir_types.dart';

class PatientFhirMapper {
  /// Converts a Patient domain model to a FHIR Patient resource Map
  static Map<String, dynamic> toFhir(Patient patient) {
    final fhirPatient = <String, dynamic>{
      'resourceType': 'Patient',
      'id': patient.id,
      'identifier': [
        if (patient.mrn.isNotEmpty)
          {
            'system': FhirSystems.identifierMrn,
            'value': patient.mrn,
            'type': {
              'coding': [
                {'system': 'http://hl7.org/fhir/identifier-type', 'code': 'MR'}
              ]
            },
          },
        if (patient.nationalId != null)
          {
            'system': FhirSystems.identifierNationalId,
            'value': patient.nationalId,
          },
        if (patient.insuranceId != null)
          {
            'system': FhirSystems.identifierInsurance,
            'value': patient.insuranceId,
            'assigner': {'display': patient.insuranceProvider},
          },
      ],
      'active': patient.status == PatientStatus.active,
      'name': [
        {
          'use': 'official',
          'family': patient.lastName,
          'given': [
            patient.firstName,
            if (patient.middleName != null) patient.middleName!,
          ],
        }
      ],
      'telecom': [
        if (patient.phone != null)
          {'system': 'phone', 'value': patient.phone!, 'use': 'mobile'},
        if (patient.phoneSecondary != null)
          {'system': 'phone', 'value': patient.phoneSecondary!, 'use': 'home'},
        if (patient.email != null) {'system': 'email', 'value': patient.email!},
      ],
      'gender': _mapGender(patient.gender),
      'birthDate': patient.dateOfBirth,
      'deceasedBoolean': patient.status == PatientStatus.deceased,
      'address': [
        {
          'line': [if (patient.address != null) patient.address!],
          'city': patient.city ?? '',
          'state': patient.state ?? '',
          'country': patient.country ?? '',
          'postalCode': patient.postalCode ?? '',
        }
      ],
      'maritalStatus': {
        'coding': [
          {
            'system': 'http://hl7.org/fhir/marital-status',
            'code': _mapMaritalStatus(patient.maritalStatus),
          }
        ]
      },
      'multipleBirthBoolean': false,
      'communication': [
        {
          'language': {
            'coding': [
              {
                'system': 'urn:ietf:bcp:47',
                'code': patient.language == Language.arabic ? 'ar' : 'en',
              }
            ]
          },
          'preferred': true,
        }
      ],
      'managingOrganization': patient.hospitalId != null
          ? {
              'reference': 'Organization/${patient.hospitalId}',
              'display': patient.hospitalName
            }
          : null,
      'generalPractitioner': [
        if (patient.createdBy != null)
          {'reference': 'Practitioner/${patient.createdBy}'}
      ],
    };

    fhirPatient.removeWhere((_, v) => v == null || (v is List && v.isEmpty));
    return fhirPatient;
  }

  /// Converts a FHIR Patient resource to a Patient domain model
  static Patient fromFhir(Map<String, dynamic> fhir) {
    final name = (fhir['name'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final given = (name?['given'] as List?)?.cast<String>() ?? [];
    final telecom =
        (fhir['telecom'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final address =
        (fhir['address'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final identifiers =
        (fhir['identifier'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    String? findIdentifier(String system) {
      final match =
          identifiers.where((id) => id['system'] == system).firstOrNull;
      return match?['value'] as String?;
    }

    String? findTelecom(String system, String use) {
      final match = telecom
          .where((t) => t['system'] == system && t['use'] == use)
          .firstOrNull;
      return match?['value'] as String?;
    }

    return Patient(
      id: fhir['id'] as String? ?? '',
      mrn: findIdentifier(FhirSystems.identifierMrn) ?? '',
      firstName: given.isNotEmpty ? given[0] : '',
      middleName: given.length > 1 ? given[1] : null,
      lastName: name?['family'] as String? ?? '',
      dateOfBirth: fhir['birthDate'] as String? ?? '',
      gender: _unmapGender(fhir['gender'] as String?),
      nationality: (address?['country'] as String?) ??
          (address?['extension'] as List?)?.firstOrNull,
      nationalId: findIdentifier(FhirSystems.identifierNationalId),
      bloodType: BloodType.unknown,
      email: findTelecom('email', ''),
      phone: findTelecom('phone', 'mobile'),
      phoneSecondary: findTelecom('phone', 'home'),
      address: (address?['line'] as List?)?.firstOrNull as String?,
      city: address?['city'] as String?,
      country: address?['country'] as String?,
      maritalStatus: MaritalStatus.single,
      language: Language.english,
      status: fhir['active'] == true
          ? PatientStatus.active
          : PatientStatus.inactive,
      hospitalId: (fhir['managingOrganization'] as Map?)?.let((m) =>
          (m['reference'] as String?)?.replaceFirst('Organization/', '')),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: false,
    );
  }

  static String _mapGender(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.other:
        return 'other';
    }
  }

  static Gender _unmapGender(String? gender) {
    switch (gender) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }

  static String _mapMaritalStatus(MaritalStatus status) {
    switch (status) {
      case MaritalStatus.single:
        return 'U';
      case MaritalStatus.married:
        return 'M';
      case MaritalStatus.divorced:
        return 'D';
      case MaritalStatus.widowed:
        return 'W';
    }
  }
}

// Helper extension
extension MapExtension<K, V> on Map<K, V> {
  dynamic let(dynamic Function(Map<K, V>) block) => block(this);
}
