import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

void main() {
  group('AnalyticsOverview', () {
    test('fromJson creates correct instance', () {
      final json = {
        'total_patients': 100,
        'active_patients': 75,
        'total_devices': 50,
        'online_devices': 40,
        'total_alerts': 25,
        'critical_alerts': 3,
        'total_hospitals': 5,
        'total_users': 20,
        'reports_generated': 15,
        'bed_occupancy_rate': 0.78,
      };
      final dto = AnalyticsOverview.fromJson(json);
      expect(dto.totalPatients, 100);
      expect(dto.activePatients, 75);
      expect(dto.totalDevices, 50);
      expect(dto.onlineDevices, 40);
      expect(dto.totalAlerts, 25);
      expect(dto.criticalAlerts, 3);
      expect(dto.totalHospitals, 5);
      expect(dto.totalUsers, 20);
      expect(dto.reportsGenerated, 15);
      expect(dto.bedOccupancyRate, 0.78);
    });

    test('fromJson handles zero values', () {
      final json = {
        'total_patients': 0, 'active_patients': 0,
        'total_devices': 0, 'online_devices': 0,
        'total_alerts': 0, 'critical_alerts': 0,
        'total_hospitals': 0, 'total_users': 0,
        'reports_generated': 0, 'bed_occupancy_rate': 0.0,
      };
      final dto = AnalyticsOverview.fromJson(json);
      expect(dto.totalPatients, 0);
      expect(dto.bedOccupancyRate, 0.0);
    });
  });

  group('PatientAnalytics', () {
    test('fromJson creates correct instance', () {
      final json = {
        'total': 100, 'active': 75, 'admitted_today': 5, 'discharged_today': 3,
        'male': 55, 'female': 45, 'average_age': 52.5,
        'average_length_of_stay_days': 4.2,
        'admissions_by_month': [{'month': '2026-01', 'count': 20}],
        'discharges_by_month': [{'month': '2026-01', 'count': 18}],
        'by_department': [{'name': 'ICU', 'count': 30}],
      };
      final dto = PatientAnalytics.fromJson(json);
      expect(dto.total, 100);
      expect(dto.active, 75);
      expect(dto.admittedToday, 5);
      expect(dto.dischargedToday, 3);
      expect(dto.male, 55);
      expect(dto.female, 45);
      expect(dto.averageAge, 52.5);
      expect(dto.averageLengthOfStayDays, 4.2);
      expect(dto.admissionsByMonth.length, 1);
      expect(dto.dischargesByMonth.length, 1);
      expect(dto.byDepartment.length, 1);
    });
  });

  group('DeviceAnalytics', () {
    test('fromJson creates correct instance', () {
      final json = {
        'total': 50, 'online': 40, 'offline': 5, 'error': 2,
        'maintenance': 1, 'sleeping': 1, 'updating': 1,
        'average_battery': 72.5, 'low_battery_count': 3,
        'by_type': [{'type': 'nb_01', 'count': 30}],
        'by_status': [{'status': 'online', 'count': 40}],
      };
      final dto = DeviceAnalytics.fromJson(json);
      expect(dto.total, 50);
      expect(dto.online, 40);
      expect(dto.offline, 5);
      expect(dto.error, 2);
      expect(dto.maintenance, 1);
      expect(dto.sleeping, 1);
      expect(dto.updating, 1);
      expect(dto.averageBattery, 72.5);
      expect(dto.lowBatteryCount, 3);
      expect(dto.byType.length, 1);
      expect(dto.byStatus.length, 1);
    });
  });

  group('AlertAnalytics', () {
    test('fromJson creates correct instance', () {
      final json = {
        'total': 25, 'critical': 3, 'high': 7, 'medium': 10, 'low': 5,
        'unacknowledged': 4, 'average_response_time_minutes': 8.5,
        'by_type': [{'type': 'icp_elevated', 'count': 10}],
        'by_severity': [{'severity': 'high', 'count': 7}],
        'by_day': [{'date': '2026-07-20', 'count': 5}],
      };
      final dto = AlertAnalytics.fromJson(json);
      expect(dto.total, 25);
      expect(dto.critical, 3);
      expect(dto.high, 7);
      expect(dto.medium, 10);
      expect(dto.low, 5);
      expect(dto.unacknowledged, 4);
      expect(dto.averageResponseTimeMinutes, 8.5);
      expect(dto.byType.length, 1);
      expect(dto.bySeverity.length, 1);
      expect(dto.byDay.length, 1);
    });
  });

  group('HospitalOverview', () {
    test('fromJson creates correct instance', () {
      final json = {
        'total_hospitals': 5, 'total_beds': 500, 'occupied_beds': 390,
        'hospitals': [
          {
            'id': 'hosp-1', 'name': 'General Hospital',
            'patient_count': 78, 'device_count': 20, 'active_alerts': 5,
            'bed_capacity': 100, 'bed_occupancy': 0.78, 'alert_trend': [],
          },
        ],
      };
      final dto = HospitalOverview.fromJson(json);
      expect(dto.totalHospitals, 5);
      expect(dto.totalBeds, 500);
      expect(dto.occupiedBeds, 390);
      expect(dto.hospitals.length, 1);
      expect(dto.hospitals[0].name, 'General Hospital');
      expect(dto.hospitals[0].bedOccupancy, 0.78);
    });
  });

  group('SystemHealth', () {
    test('fromJson creates correct instance', () {
      final json = {
        'total_requests_24h': 15000,
        'active_web_sockets': 25,
        'avg_response_time_ms': 245.0,
        'error_rate_24h': 0.02,
        'database_connections': 10,
        'cache_hit_rate': 0.85,
        'uptime_hours': 720.0,
        'recent_errors': [{'message': 'Timeout', 'timestamp': '2026-07-24T12:00:00Z'}],
        'service_status': [{'service': 'api', 'status': 'healthy'}],
      };
      final dto = SystemHealth.fromJson(json);
      expect(dto.totalRequests24h, 15000);
      expect(dto.activeWebSockets, 25);
      expect(dto.avgResponseTimeMs, 245.0);
      expect(dto.errorRate24h, 0.02);
      expect(dto.databaseConnections, 10);
      expect(dto.cacheHitRate, 0.85);
      expect(dto.uptimeHours, 720.0);
      expect(dto.recentErrors.length, 1);
      expect(dto.serviceStatus.length, 1);
    });
  });

  group('ActivityFeedItem', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 'feed-1',
        'event_type': 'alert_created',
        'description': 'Critical alert for patient John Doe',
        'entity_type': 'alert',
        'entity_id': 'alert-123',
        'user_name': 'Dr. Smith',
        'timestamp': '2026-07-24T10:30:00Z',
        'metadata': {'severity': 'critical'},
      };
      final dto = ActivityFeedItem.fromJson(json);
      expect(dto.id, 'feed-1');
      expect(dto.eventType, 'alert_created');
      expect(dto.entityType, 'alert');
      expect(dto.entityId, 'alert-123');
      expect(dto.userName, 'Dr. Smith');
      expect(dto.metadata, isNotNull);
    });

    test('fromJson handles null fields', () {
      final json = {
        'id': 'feed-2', 'event_type': 'device_registered',
        'description': 'Device registered', 'entity_type': 'device',
        'entity_id': null, 'user_name': null,
        'timestamp': '2026-07-24T11:00:00Z', 'metadata': null,
      };
      final dto = ActivityFeedItem.fromJson(json);
      expect(dto.id, 'feed-2');
      expect(dto.entityId, isNull);
      expect(dto.userName, isNull);
      expect(dto.metadata, isNull);
    });
  });
}
