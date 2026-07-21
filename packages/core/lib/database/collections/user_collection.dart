import 'package:isar_community/isar.dart';
import 'package:shared/shared.dart';

part 'user_collection.isar_generator.g.part';

@collection
class UserCollection {
  Id? isarId;

  @Index(unique: true)
  late String id;

  @Index(unique: true)
  late String email;

  String? phone;
  String? displayName;
  String? photoUrl;
  late String role;
  late String authProvider;
  late bool isActive;

  @Index()
  String? hospitalId;

  late DateTime createdAt;
  late DateTime updatedAt;

  UserCollection();

  User toEntity() => User(
        id: id,
        email: email,
        phone: phone,
        displayName: displayName,
        photoUrl: photoUrl,
        role: UserRole.values.firstWhere((r) => r.name == role),
        authProvider:
            AuthProvider.values.firstWhere((a) => a.name == authProvider),
        isActive: isActive,
        hospitalId: hospitalId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory UserCollection.fromEntity(User u) => UserCollection()
    ..id = u.id
    ..email = u.email
    ..phone = u.phone
    ..displayName = u.displayName
    ..photoUrl = u.photoUrl
    ..role = u.role.name
    ..authProvider = u.authProvider.name
    ..isActive = u.isActive
    ..hospitalId = u.hospitalId
    ..createdAt = u.createdAt
    ..updatedAt = u.updatedAt;

  Map<String, dynamic> toJson() => {
        'isarId': isarId,
        'id': id,
        'email': email,
        'phone': phone,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role,
        'authProvider': authProvider,
        'isActive': isActive,
        'hospitalId': hospitalId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserCollection.fromJson(Map<String, dynamic> json) => UserCollection()
    ..isarId = json['isarId'] as int?
    ..id = json['id'] as String
    ..email = json['email'] as String
    ..phone = json['phone'] as String?
    ..displayName = json['displayName'] as String?
    ..photoUrl = json['photoUrl'] as String?
    ..role = json['role'] as String
    ..authProvider = json['authProvider'] as String
    ..isActive = json['isActive'] as bool? ?? true
    ..hospitalId = json['hospitalId'] as String?
    ..createdAt = DateTime.parse(json['createdAt'] as String)
    ..updatedAt = DateTime.parse(json['updatedAt'] as String);
}
