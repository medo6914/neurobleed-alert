import 'package:equatable/equatable.dart';

class EmergencyContact extends Equatable {
  final String id;
  final String patientId;
  final String name;
  final String relationship;
  final String? phone;
  final String? phoneSecondary;
  final String? email;
  final String? address;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmergencyContact({
    required this.id,
    required this.patientId,
    required this.name,
    required this.relationship,
    this.phone,
    this.phoneSecondary,
    this.email,
    this.address,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  EmergencyContact copyWith({
    String? id,
    String? patientId,
    String? name,
    String? relationship,
    String? phone,
    String? phoneSecondary,
    String? email,
    String? address,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      email: email ?? this.email,
      address: address ?? this.address,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      phone: json['phone'] as String?,
      phoneSecondary: json['phoneSecondary'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'phoneSecondary': phoneSecondary,
      'email': email,
      'address': address,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, patientId, name, relationship, isPrimary];
}
