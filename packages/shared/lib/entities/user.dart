import 'package:equatable/equatable.dart';

enum UserRole {
  super_admin,
  admin,
  user,
  doctor,
  nurse,
  technician,
  patient,
  emergency,
  researcher,
  family,
}

enum AuthProvider {
  email,
  google,
  phone,
}

class User extends Equatable {
  final String id;
  final String email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final AuthProvider authProvider;
  final bool isActive;
  final String? hospitalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.doctor,
    this.authProvider = AuthProvider.email,
    this.isActive = true,
    this.hospitalId,
    required this.createdAt,
    required this.updatedAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    AuthProvider? authProvider,
    bool? isActive,
    String? hospitalId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      authProvider: authProvider ?? this.authProvider,
      isActive: isActive ?? this.isActive,
      hospitalId: hospitalId ?? this.hospitalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        phone,
        displayName,
        photoUrl,
        role,
        authProvider,
        isActive,
        hospitalId,
        createdAt,
        updatedAt,
      ];
}
