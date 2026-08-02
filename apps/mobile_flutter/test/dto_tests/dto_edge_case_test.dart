import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  group('Analytics DTO edge cases', () {
    test('AnalyticsOverview handles zero bed occupancy', () {
      final json = {
        'total_patients': 0, 'active_patients': 0,
        'total_devices': 0, 'online_devices': 0,
        'total_alerts': 0, 'critical_alerts': 0,
        'total_hospitals': 0, 'total_users': 0,
        'reports_generated': 0, 'bed_occupancy_rate': 0.0,
      };
      final dto = AnalyticsOverview.fromJson(json);
      expect(dto.bedOccupancyRate, 0.0);
      expect(dto.totalPatients, 0);
    });

    test('PatientAnalytics handles empty lists', () {
      final json = {
        'total': 0, 'active': 0, 'admitted_today': 0, 'discharged_today': 0,
        'male': 0, 'female': 0, 'average_age': 0.0, 'average_length_of_stay_days': 0.0,
        'admissions_by_month': <Map<String, dynamic>>[],
        'discharges_by_month': <Map<String, dynamic>>[],
        'by_department': <Map<String, dynamic>>[],
      };
      final dto = PatientAnalytics.fromJson(json);
      expect(dto.admissionsByMonth, isEmpty);
      expect(dto.byDepartment, isEmpty);
    });

    test('DeviceAnalytics handles zero state', () {
      final json = {
        'total': 0, 'online': 0, 'offline': 0, 'error': 0,
        'maintenance': 0, 'sleeping': 0, 'updating': 0,
        'average_battery': 0.0, 'low_battery_count': 0,
        'by_type': <Map<String, dynamic>>[],
        'by_status': <Map<String, dynamic>>[],
      };
      final dto = DeviceAnalytics.fromJson(json);
      expect(dto.total, 0);
      expect(dto.averageBattery, 0.0);
    });

    test('AlertAnalytics handles zero state', () {
      final json = {
        'total': 0, 'critical': 0, 'high': 0, 'medium': 0, 'low': 0,
        'unacknowledged': 0, 'average_response_time_minutes': 0.0,
        'by_type': <Map<String, dynamic>>[],
        'by_severity': <Map<String, dynamic>>[],
        'by_day': <Map<String, dynamic>>[],
      };
      final dto = AlertAnalytics.fromJson(json);
      expect(dto.total, 0);
      expect(dto.averageResponseTimeMinutes, 0.0);
    });

    test('HospitalOverview handles empty hospital list', () {
      final json = {
        'total_hospitals': 0, 'total_beds': 0, 'occupied_beds': 0,
        'hospitals': <Map<String, dynamic>>[],
      };
      final dto = HospitalOverview.fromJson(json);
      expect(dto.hospitals, isEmpty);
    });

    test('HospitalMetrics handles null alert_trend', () {
      final json = {
        'id': 'h-1', 'name': 'Test Hospital', 'patient_count': 0,
        'device_count': 0, 'active_alerts': 0, 'bed_capacity': 0,
        'bed_occupancy': 0.0, 'alert_trend': null,
      };
      final dto = HospitalMetrics.fromJson(json);
      expect(dto.alertTrend, isEmpty);
    });

    test('SystemHealth handles large numbers', () {
      final json = {
        'total_requests_24h': 9999999, 'active_web_sockets': 1000,
        'avg_response_time_ms': 999.9, 'error_rate_24h': 0.99,
        'database_connections': 100, 'cache_hit_rate': 0.999,
        'uptime_hours': 8760.0,
        'recent_errors': <Map<String, dynamic>>[],
        'service_status': <Map<String, dynamic>>[],
      };
      final dto = SystemHealth.fromJson(json);
      expect(dto.totalRequests24h, 9999999);
      expect(dto.errorRate24h, 0.99);
    });

    test('ActivityFeedItem handles very long description', () {
      final longDesc = 'A' * 1000;
      final json = {
        'id': 'feed-3', 'event_type': 'test', 'description': longDesc,
        'entity_type': 'test', 'entity_id': null, 'user_name': null,
        'timestamp': '2026-01-01T00:00:00Z', 'metadata': null,
      };
      final dto = ActivityFeedItem.fromJson(json);
      expect(dto.description.length, 1000);
    });
  });

  group('Provisioning DTO edge cases', () {
    test('ProvisioningKey with all fields populated', () {
      final json = {
        'id': 'pk-full', 'key': 'NB-FULL-KEY',
        'device_type': 'nb_02', 'label': 'Ward B Monitor',
        'status': 'expired', 'expires_at': '2025-01-01T00:00:00Z',
        'used_at': null, 'max_uses': 10, 'use_count': 8,
        'created_at': '2024-06-01T00:00:00Z',
      };
      final dto = ProvisioningKey.fromJson(json);
      expect(dto.status, 'expired');
      expect(dto.expiresAt, isNotNull);
      expect(dto.maxUses, 10);
      expect(dto.useCount, 8);
    });

    test('ProvisioningClaimRequest with only required fields', () {
      final req = ProvisioningClaimRequest(
        provisioningKey: 'NB-MIN-KEY',
        serialNumber: 'SN-MIN-001',
      );
      final json = req.toJson();
      expect(json.length, 2);
    });
  });

  group('Failure types', () {
    test('NotFoundFailure has correct type', () {
      const failure = NotFoundFailure(message: 'Not found');
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'Not found');
    });

    test('TimeoutFailure has correct type', () {
      const failure = TimeoutFailure(message: 'Timed out');
      expect(failure, isA<TimeoutFailure>());
    });

    test('CacheFailure has correct type', () {
      const failure = CacheFailure(message: 'Cache miss');
      expect(failure, isA<CacheFailure>());
    });
  });
}
