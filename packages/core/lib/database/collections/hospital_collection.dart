import 'package:isar_community/isar.dart';
import 'package:shared/shared.dart';

part 'hospital_collection.isar_generator.g.part';

@collection
class HospitalCollection {
  Id? isarId;

  @Index(unique: true)
  late String id;

  @Index()
  late String name;

  String? address;
  String? city;
  String? country;
  String? phone;
  String? timezone;
  late bool isActive;
  late DateTime createdAt;

  HospitalCollection();

  Hospital toEntity() => Hospital(
        id: id,
        name: name,
        address: address,
        city: city,
        country: country,
        phone: phone,
        timezone: timezone,
        isActive: isActive,
        createdAt: createdAt,
      );

  factory HospitalCollection.fromEntity(Hospital h) => HospitalCollection()
    ..id = h.id
    ..name = h.name
    ..address = h.address
    ..city = h.city
    ..country = h.country
    ..phone = h.phone
    ..timezone = h.timezone
    ..isActive = h.isActive
    ..createdAt = h.createdAt;

  Map<String, dynamic> toJson() => {
        'isarId': isarId,
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'country': country,
        'phone': phone,
        'timezone': timezone,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HospitalCollection.fromJson(Map<String, dynamic> json) =>
      HospitalCollection()
        ..isarId = json['isarId'] as int?
        ..id = json['id'] as String
        ..name = json['name'] as String
        ..address = json['address'] as String?
        ..city = json['city'] as String?
        ..country = json['country'] as String?
        ..phone = json['phone'] as String?
        ..timezone = json['timezone'] as String?
        ..isActive = json['isActive'] as bool? ?? true
        ..createdAt = DateTime.parse(json['createdAt'] as String);
}
