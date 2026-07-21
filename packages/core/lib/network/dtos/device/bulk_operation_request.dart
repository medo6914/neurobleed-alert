class BulkOperationRequest {
  final List<String> deviceIds;
  final String operation;
  final String? firmwareVersion;

  const BulkOperationRequest({
    required this.deviceIds,
    required this.operation,
    this.firmwareVersion,
  });

  factory BulkOperationRequest.fromJson(Map<String, dynamic> json) =>
      BulkOperationRequest(
        deviceIds: (json['device_ids'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        operation: json['operation'] as String,
        firmwareVersion: json['firmware_version'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'device_ids': deviceIds,
        'operation': operation,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      };
}
