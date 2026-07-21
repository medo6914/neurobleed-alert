import 'package:equatable/equatable.dart';

enum Gender { male, female, other }

enum BloodType { aPositive, aNegative, bPositive, bNegative, abPositive, abNegative, oPositive, oNegative, unknown }

enum PatientStatus { active, inactive, transferred, deceased }

enum MaritalStatus { single, married, divorced, widowed }

enum Language { english, arabic, other }

class Patient extends Equatable {
  final String id;
  final String mrn;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String dateOfBirth;
  final Gender gender;
  final String? nationality;
  final String? nationalId;
  final BloodType bloodType;
  final double? weight;
  final double? height;
  final String? email;
  final String? phone;
  final String? phoneSecondary;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final MaritalStatus maritalStatus;
  final Language language;
  final String? occupation;
  final String? employer;
  final String? insuranceProvider;
  final String? insuranceId;
  final String? insurancePolicyNumber;
  final PatientStatus status;
  final String? hospitalId;
  final String? hospitalName;
  final String? departmentId;
  final String? departmentName;
  final String? ward;
  final String? bedNumber;
  final String? primaryDiagnosis;
  final List<String> diagnoses;
  final List<String> allergies;
  final List<String> medications;
  final List<String> comorbidities;
  final List<String> surgicalHistory;
  final List<String> familyHistory;
  final List<String> socialHistory;
  final String? notes;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final bool isDeleted;

  const Patient({
    required this.id,
    required this.mrn,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    this.nationality,
    this.nationalId,
    this.bloodType = BloodType.unknown,
    this.weight,
    this.height,
    this.email,
    this.phone,
    this.phoneSecondary,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.maritalStatus = MaritalStatus.single,
    this.language = Language.english,
    this.occupation,
    this.employer,
    this.insuranceProvider,
    this.insuranceId,
    this.insurancePolicyNumber,
    this.status = PatientStatus.active,
    this.hospitalId,
    this.hospitalName,
    this.departmentId,
    this.departmentName,
    this.ward,
    this.bedNumber,
    this.primaryDiagnosis,
    this.diagnoses = const [],
    this.allergies = const [],
    this.medications = const [],
    this.comorbidities = const [],
    this.surgicalHistory = const [],
    this.familyHistory = const [],
    this.socialHistory = const [],
    this.notes,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.isDeleted = false,
  });

  String get fullName => '${firstName}${middleName != null ? ' $middleName ' : ' '}$lastName';

  Patient copyWith({
    String? id,
    String? mrn,
    String? firstName,
    String? middleName,
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
    String? phoneSecondary,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    MaritalStatus? maritalStatus,
    Language? language,
    String? occupation,
    String? employer,
    String? insuranceProvider,
    String? insuranceId,
    String? insurancePolicyNumber,
    PatientStatus? status,
    String? hospitalId,
    String? hospitalName,
    String? departmentId,
    String? departmentName,
    String? ward,
    String? bedNumber,
    String? primaryDiagnosis,
    List<String>? diagnoses,
    List<String>? allergies,
    List<String>? medications,
    List<String>? comorbidities,
    List<String>? surgicalHistory,
    List<String>? familyHistory,
    List<String>? socialHistory,
    String? notes,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return Patient(
      id: id ?? this.id,
      mrn: mrn ?? this.mrn,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      nationalId: nationalId ?? this.nationalId,
      bloodType: bloodType ?? this.bloodType,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      language: language ?? this.language,
      occupation: occupation ?? this.occupation,
      employer: employer ?? this.employer,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceId: insuranceId ?? this.insuranceId,
      insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
      status: status ?? this.status,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      ward: ward ?? this.ward,
      bedNumber: bedNumber ?? this.bedNumber,
      primaryDiagnosis: primaryDiagnosis ?? this.primaryDiagnosis,
      diagnoses: diagnoses ?? this.diagnoses,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      comorbidities: comorbidities ?? this.comorbidities,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      socialHistory: socialHistory ?? this.socialHistory,
      notes: notes ?? this.notes,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      mrn: json['mrn'] as String,
      firstName: json['firstName'] as String,
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
      gender: Gender.values.firstWhere((e) => e.name == json['gender']),
      nationality: json['nationality'] as String?,
      nationalId: json['nationalId'] as String?,
      bloodType: json['bloodType'] != null
          ? BloodType.values.firstWhere((e) => e.name == json['bloodType'])
          : BloodType.unknown,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      phoneSecondary: json['phoneSecondary'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      maritalStatus: json['maritalStatus'] != null
          ? MaritalStatus.values.firstWhere((e) => e.name == json['maritalStatus'])
          : MaritalStatus.single,
      language: json['language'] != null
          ? Language.values.firstWhere((e) => e.name == json['language'])
          : Language.english,
      occupation: json['occupation'] as String?,
      employer: json['employer'] as String?,
      insuranceProvider: json['insuranceProvider'] as String?,
      insuranceId: json['insuranceId'] as String?,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
      status: json['status'] != null
          ? PatientStatus.values.firstWhere((e) => e.name == json['status'])
          : PatientStatus.active,
      hospitalId: json['hospitalId'] as String?,
      hospitalName: json['hospitalName'] as String?,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      ward: json['ward'] as String?,
      bedNumber: json['bedNumber'] as String?,
      primaryDiagnosis: json['primaryDiagnosis'] as String?,
      diagnoses: json['diagnoses'] != null ? List<String>.from(json['diagnoses'] as List) : const [],
      allergies: json['allergies'] != null ? List<String>.from(json['allergies'] as List) : const [],
      medications: json['medications'] != null ? List<String>.from(json['medications'] as List) : const [],
      comorbidities: json['comorbidities'] != null ? List<String>.from(json['comorbidities'] as List) : const [],
      surgicalHistory: json['surgicalHistory'] != null ? List<String>.from(json['surgicalHistory'] as List) : const [],
      familyHistory: json['familyHistory'] != null ? List<String>.from(json['familyHistory'] as List) : const [],
      socialHistory: json['socialHistory'] != null ? List<String>.from(json['socialHistory'] as List) : const [],
      notes: json['notes'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mrn': mrn,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender.name,
      'nationality': nationality,
      'nationalId': nationalId,
      'bloodType': bloodType.name,
      'weight': weight,
      'height': height,
      'email': email,
      'phone': phone,
      'phoneSecondary': phoneSecondary,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'maritalStatus': maritalStatus.name,
      'language': language.name,
      'occupation': occupation,
      'employer': employer,
      'insuranceProvider': insuranceProvider,
      'insuranceId': insuranceId,
      'insurancePolicyNumber': insurancePolicyNumber,
      'status': status.name,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'ward': ward,
      'bedNumber': bedNumber,
      'primaryDiagnosis': primaryDiagnosis,
      'diagnoses': diagnoses,
      'allergies': allergies,
      'medications': medications,
      'comorbidities': comorbidities,
      'surgicalHistory': surgicalHistory,
      'familyHistory': familyHistory,
      'socialHistory': socialHistory,
      'notes': notes,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  @override
  List<Object?> get props => [id, mrn, firstName, lastName, dateOfBirth, gender, status];
}
