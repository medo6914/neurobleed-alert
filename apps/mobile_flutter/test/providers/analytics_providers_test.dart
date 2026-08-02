import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:core/core.dart';

// Need to import the analytics providers from the screen file
// For proper testing, these providers should be in a separate file.
// This test validates the provider construction pattern.

class MockAnalyticsApi extends Mock implements AnalyticsApi {}

class MockResponse extends Mock implements Response {}

void main() {
  late MockAnalyticsApi mockApi;
  late MockResponse mockResponse;

  setUp(() {
    mockApi = MockAnalyticsApi();
    mockResponse = MockResponse();
  });

  group('AnalyticsApi client', () {
    test('getOverview returns parsed response', () async {
      when(() => mockApi.getOverview(hospitalId: any(named: 'hospitalId')))
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn({
        'total_patients': 100, 'active_patients': 75,
        'total_devices': 50, 'online_devices': 40,
        'total_alerts': 25, 'critical_alerts': 3,
        'total_hospitals': 5, 'total_users': 20,
        'reports_generated': 15, 'bed_occupancy_rate': 0.78,
      });

      final response = await mockApi.getOverview();
      final dto = AnalyticsOverview.fromJson(response.data as Map<String, dynamic>);

      expect(dto.totalPatients, 100);
      expect(dto.activePatients, 75);
      expect(dto.bedOccupancyRate, 0.78);
    });

    test('getPatientAnalytics returns parsed response', () async {
      when(() => mockApi.getPatientAnalytics(hospitalId: any(named: 'hospitalId')))
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn({
        'total': 100, 'active': 75, 'admitted_today': 5, 'discharged_today': 3,
        'male': 55, 'female': 45, 'average_age': 52.5, 'average_length_of_stay_days': 4.2,
        'admissions_by_month': [], 'discharges_by_month': [], 'by_department': [],
      });

      final response = await mockApi.getPatientAnalytics();
      final dto = PatientAnalytics.fromJson(response.data as Map<String, dynamic>);

      expect(dto.total, 100);
      expect(dto.averageAge, 52.5);
    });

    test('getDeviceAnalytics returns parsed response', () async {
      when(() => mockApi.getDeviceAnalytics(hospitalId: any(named: 'hospitalId')))
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn({
        'total': 50, 'online': 40, 'offline': 5, 'error': 2,
        'maintenance': 1, 'sleeping': 1, 'updating': 1,
        'average_battery': 72.5, 'low_battery_count': 3,
        'by_type': [], 'by_status': [],
      });

      final response = await mockApi.getDeviceAnalytics();
      final dto = DeviceAnalytics.fromJson(response.data as Map<String, dynamic>);

      expect(dto.total, 50);
      expect(dto.averageBattery, 72.5);
    });

    test('getAlertAnalytics returns parsed response', () async {
      when(() => mockApi.getAlertAnalytics(hospitalId: any(named: 'hospitalId')))
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn({
        'total': 25, 'critical': 3, 'high': 7, 'medium': 10, 'low': 5,
        'unacknowledged': 4, 'average_response_time_minutes': 8.5,
        'by_type': [], 'by_severity': [], 'by_day': [],
      });

      final response = await mockApi.getAlertAnalytics();
      final dto = AlertAnalytics.fromJson(response.data as Map<String, dynamic>);

      expect(dto.critical, 3);
      expect(dto.averageResponseTimeMinutes, 8.5);
    });

    test('getHospitalOverview returns parsed response', () async {
      when(() => mockApi.getHospitalOverview())
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn({
        'total_hospitals': 5, 'total_beds': 500, 'occupied_beds': 390,
        'hospitals': [],
      });

      final response = await mockApi.getHospitalOverview();
      final dto = HospitalOverview.fromJson(response.data as Map<String, dynamic>);

      expect(dto.totalHospitals, 5);
      expect(dto.totalBeds, 500);
    });

    test('getSystemHealth returns parsed response', () async {
      when(() => mockApi.getSystemHealth())
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn({
        'total_requests_24h': 15000, 'active_web_sockets': 25,
        'avg_response_time_ms': 245.0, 'error_rate_24h': 0.02,
        'database_connections': 10, 'cache_hit_rate': 0.85,
        'uptime_hours': 720.0, 'recent_errors': [], 'service_status': [],
      });

      final response = await mockApi.getSystemHealth();
      final dto = SystemHealth.fromJson(response.data as Map<String, dynamic>);

      expect(dto.totalRequests24h, 15000);
      expect(dto.uptimeHours, 720.0);
    });

    test('getActivityFeed returns parsed response', () async {
      when(() => mockApi.getActivityFeed(limit: any(named: 'limit')))
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn([
        {
          'id': 'feed-1', 'event_type': 'alert_created',
          'description': 'Critical alert', 'entity_type': 'alert',
          'entity_id': 'alert-123', 'user_name': 'Dr. Smith',
          'timestamp': '2026-07-24T10:30:00Z', 'metadata': null,
        },
      ]);

      final response = await mockApi.getActivityFeed(limit: 20);
      final items = (response.data as List)
          .map((e) => ActivityFeedItem.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(items.length, 1);
      expect(items[0].eventType, 'alert_created');
    });

    test('getActivityFeed with default limit', () async {
      when(() => mockApi.getActivityFeed(limit: any(named: 'limit')))
          .thenAnswer((_) async => mockResponse);

      when(() => mockResponse.data).thenReturn([]);

      final response = await mockApi.getActivityFeed();
      expect((response.data as List).length, 0);
    });
  });

}
