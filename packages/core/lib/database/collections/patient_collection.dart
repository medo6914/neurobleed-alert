import 'package:isar_community/isar.dart';
import 'package:shared/shared.dart';

part 'patient_collection.isar_generator.g.part';

@collection
class PatientCollection {
  Id? isarId;

  @Index(unique: true)
  late String id;

  @Index()
  late String mrn;

  late String firstName;
  late String lastName;
  late String dateOfBirth;
  late String gender;
  String? bloodType;
  double? weight;
  double? height;

  @Index()
  String? hospitalId;

  String? ward;
  String? bedNumber;
  late String status;
  String? primaryDiagnosis;
  List<String> comorbidities = [];
  List<String> allergies = [];
  String? emergencyContactId;
  String? notes;
  late DateTime createdAt;
  late DateTime updatedAt;

  PatientCollection();

  Patient toEntity() => Patient(
        id: id,
        mrn: mrn,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: Gender.values.firstWhere((g) => g.name == gender),
        bloodType: bloodType != null
            ? BloodType.values.firstWhere((b) => b.name == bloodType!)
            : BloodType.unknown,
        weight: weight,
        height: height,
        hospitalId: hospitalId,
        ward: ward,
        bedNumber: bedNumber,
        status: PatientStatus.values.firstWhere((s) => s.name == status),
        primaryDiagnosis: primaryDiagnosis,
        comorbidities: List<String>.from(comorbidities),
        allergies: List<String>.from(allergies),
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory PatientCollection.fromEntity(Patient p) => PatientCollection()
    ..id = p.id
    ..mrn = p.mrn
    ..firstName = p.firstName
    ..lastName = p.lastName
    ..dateOfBirth = p.dateOfBirth
    ..gender = p.gender.name
    ..bloodType = p.bloodType?.name
    ..weight = p.weight
    ..height = p.height
    ..hospitalId = p.hospitalId
    ..ward = p.ward
    ..bedNumber = p.bedNumber
    ..status = p.status.name
    ..primaryDiagnosis = p.primaryDiagnosis
    ..comorbidities = List<String>.from(p.comorbidities)
    ..allergies = List<String>.from(p.allergies)
    ..notes = p.notes
    ..createdAt = p.createdAt
    ..updatedAt = p.updatedAt;

  Map<String, dynamic> toJson() => {
        'isarId': isarId,
        'id': id,
        'mrn': mrn,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'bloodType': bloodType,
        'weight': weight,
        'height': height,
        'hospitalId': hospitalId,
        'ward': ward,
        'bedNumber': bedNumber,
        'status': status,
        'primaryDiagnosis': primaryDiagnosis,
        'comorbidities': comorbidities,
        'allergies': allergies,
        'emergencyContactId': emergencyContactId,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PatientCollection.fromJson(Map<String, dynamic> json) =>
      PatientCollection()
        ..isarId = json['isarId'] as int?
        ..id = json['id'] as String
        ..mrn = json['mrn'] as String
        ..firstName = json['firstName'] as String
        ..lastName = json['lastName'] as String
        ..dateOfBirth = json['dateOfBirth'] as String
        ..gender = json['gender'] as String
        ..bloodType = json['bloodType'] as String?
        ..weight = (json['weight'] as num?)?.toDouble()
        ..height = (json['height'] as num?)?.toDouble()
        ..hospitalId = json['hospitalId'] as String?
        ..ward = json['ward'] as String?
        ..bedNumber = json['bedNumber'] as String?
        ..status = json['status'] as String
        ..primaryDiagnosis = json['primaryDiagnosis'] as String?
        ..comorbidities = json['comorbidities'] != null
            ? List<String>.from(json['comorbidities'] as List)
            : []
        ..allergies = json['allergies'] != null
            ? List<String>.from(json['allergies'] as List)
            : []
        ..emergencyContactId = json['emergencyContactId'] as String?
        ..notes = json['notes'] as String?
        ..createdAt = DateTime.parse(json['createdAt'] as String)
        ..updatedAt = DateTime.parse(json['updatedAt'] as String);
}
