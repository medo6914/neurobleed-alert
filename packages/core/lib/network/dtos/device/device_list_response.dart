import 'device_dto.dart';

class DeviceListResponse {
  final List<DeviceDto> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const DeviceListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) =>
      DeviceListResponse(
        items: (json['data'] as List<dynamic>)
            .map((e) => DeviceDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        perPage: json['per_page'] as int,
        totalPages: json['total_pages'] as int,
        hasNext: json['has_next'] as bool,
        hasPrev: json['has_prev'] as bool,
      );
}
