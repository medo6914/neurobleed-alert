import 'package:shared/shared.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';

class AuditLogger {
  final ApiClient _apiClient;
  final AppLogger _logger;
  final List<AuditRecord> _pendingRecords = [];
  bool _isOnline = true;

  AuditLogger(this._apiClient, this._logger);

  Future<void> log({
    required String patientId,
    String? userId,
    String? userName,
    String? userRole,
    required String action,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? changes,
    String? details,
  }) async {
    final record = AuditRecord(
      id: '',
      patientId: patientId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      changes: changes,
      ipAddress: null,
      userAgent: null,
      details: details,
      timestamp: DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      if (_isOnline) {
        await _apiClient.post('/v1/audit/log', data: record.toJson());
      } else {
        _pendingRecords.add(record);
      }
    } catch (e) {
      _logger.error('Failed to log audit record', error: e);
      _pendingRecords.add(record);
    }
  }

  Future<void> logCreate({
    required String patientId,
    required String resourceType,
    String? resourceId,
    String? userId,
    String? userName,
    String? userRole,
  }) {
    return log(
      patientId: patientId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      action: 'create',
      resourceType: resourceType,
      resourceId: resourceId,
    );
  }

  Future<void> logUpdate({
    required String patientId,
    required String resourceType,
    String? resourceId,
    Map<String, dynamic>? changes,
    String? userId,
    String? userName,
    String? userRole,
  }) {
    return log(
      patientId: patientId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      action: 'update',
      resourceType: resourceType,
      resourceId: resourceId,
      changes: changes,
    );
  }

  Future<void> logDelete({
    required String patientId,
    required String resourceType,
    String? resourceId,
    String? userId,
    String? userName,
    String? userRole,
  }) {
    return log(
      patientId: patientId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      action: 'delete',
      resourceType: resourceType,
      resourceId: resourceId,
    );
  }

  Future<void> logViewSensitive({
    required String patientId,
    required String resourceType,
    String? resourceId,
    String? userId,
    String? userName,
    String? userRole,
  }) {
    return log(
      patientId: patientId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      action: 'view_sensitive',
      resourceType: resourceType,
      resourceId: resourceId,
    );
  }

  Future<void> flushPending() async {
    if (_pendingRecords.isEmpty) return;
    final records = List<AuditRecord>.from(_pendingRecords);
    _pendingRecords.clear();
    for (final record in records) {
      try {
        await _apiClient.post('/v1/audit/log', data: record.toJson());
      } catch (e) {
        _pendingRecords.add(record);
        _logger.error('Failed to flush audit record', error: e);
      }
    }
  }

  void setOnline(bool online) {
    _isOnline = online;
    if (online) {
      flushPending();
    }
  }
}
