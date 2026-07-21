import 'package:equatable/equatable.dart';

class Hospital extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String? timezone;
  final bool isActive;
  final DateTime createdAt;

  const Hospital({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.country,
    this.phone,
    this.timezone,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name];
}
