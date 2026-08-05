class AnalyticsOverview {
  final int totalPatients;
  final int activePatients;
  final int totalDevices;
  final int onlineDevices;
  final int totalAlerts;
  final int criticalAlerts;
  final int totalHospitals;
  final int totalUsers;
  final int reportsGenerated;
  final double bedOccupancyRate;

  const AnalyticsOverview({
    required this.totalPatients,
    required this.activePatients,
    required this.totalDevices,
    required this.onlineDevices,
    required this.totalAlerts,
    required this.criticalAlerts,
    required this.totalHospitals,
    required this.totalUsers,
    required this.reportsGenerated,
    required this.bedOccupancyRate,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) =>
      AnalyticsOverview(
        totalPatients: (json['total_patients'] as num).toInt(),
        activePatients: (json['active_patients'] as num).toInt(),
        totalDevices: (json['total_devices'] as num).toInt(),
        onlineDevices: (json['online_devices'] as num).toInt(),
        totalAlerts: (json['total_alerts'] as num).toInt(),
        criticalAlerts: (json['critical_alerts'] as num).toInt(),
        totalHospitals: (json['total_hospitals'] as num).toInt(),
        totalUsers: (json['total_users'] as num).toInt(),
        reportsGenerated: (json['reports_generated'] as num).toInt(),
        bedOccupancyRate: (json['bed_occupancy_rate'] as num).toDouble(),
      );
}

class PatientAnalytics {
  final int total;
  final int active;
  final int admittedToday;
  final int dischargedToday;
  final int male;
  final int female;
  final double averageAge;
  final double averageLengthOfStayDays;
  final List<Map<String, dynamic>> admissionsByMonth;
  final List<Map<String, dynamic>> dischargesByMonth;
  final List<Map<String, dynamic>> byDepartment;

  const PatientAnalytics({
    required this.total,
    required this.active,
    required this.admittedToday,
    required this.dischargedToday,
    required this.male,
    required this.female,
    required this.averageAge,
    required this.averageLengthOfStayDays,
    required this.admissionsByMonth,
    required this.dischargesByMonth,
    required this.byDepartment,
  });

  factory PatientAnalytics.fromJson(Map<String, dynamic> json) =>
      PatientAnalytics(
        total: (json['total'] as num).toInt(),
        active: (json['active'] as num).toInt(),
        admittedToday: (json['admitted_today'] as num).toInt(),
        dischargedToday: (json['discharged_today'] as num).toInt(),
        male: (json['male'] as num).toInt(),
        female: (json['female'] as num).toInt(),
        averageAge: (json['average_age'] as num).toDouble(),
        averageLengthOfStayDays:
            (json['average_length_of_stay_days'] as num).toDouble(),
        admissionsByMonth:
            (json['admissions_by_month'] as List).cast<Map<String, dynamic>>(),
        dischargesByMonth:
            (json['discharges_by_month'] as List).cast<Map<String, dynamic>>(),
        byDepartment:
            (json['by_department'] as List).cast<Map<String, dynamic>>(),
      );
}

class DeviceAnalytics {
  final int total;
  final int online;
  final int offline;
  final int error;
  final int maintenance;
  final int sleeping;
  final int updating;
  final double averageBattery;
  final int lowBatteryCount;
  final List<Map<String, dynamic>> byType;
  final List<Map<String, dynamic>> byStatus;

  const DeviceAnalytics({
    required this.total,
    required this.online,
    required this.offline,
    required this.error,
    required this.maintenance,
    required this.sleeping,
    required this.updating,
    required this.averageBattery,
    required this.lowBatteryCount,
    required this.byType,
    required this.byStatus,
  });

  factory DeviceAnalytics.fromJson(Map<String, dynamic> json) =>
      DeviceAnalytics(
        total: (json['total'] as num).toInt(),
        online: (json['online'] as num).toInt(),
        offline: (json['offline'] as num).toInt(),
        error: (json['error'] as num).toInt(),
        maintenance: (json['maintenance'] as num).toInt(),
        sleeping: (json['sleeping'] as num).toInt(),
        updating: (json['updating'] as num).toInt(),
        averageBattery: (json['average_battery'] as num).toDouble(),
        lowBatteryCount: (json['low_battery_count'] as num).toInt(),
        byType: (json['by_type'] as List).cast<Map<String, dynamic>>(),
        byStatus: (json['by_status'] as List).cast<Map<String, dynamic>>(),
      );
}

class AlertAnalytics {
  final int total;
  final int critical;
  final int high;
  final int medium;
  final int low;
  final int unacknowledged;
  final double averageResponseTimeMinutes;
  final List<Map<String, dynamic>> byType;
  final List<Map<String, dynamic>> bySeverity;
  final List<Map<String, dynamic>> byDay;

  const AlertAnalytics({
    required this.total,
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
    required this.unacknowledged,
    required this.averageResponseTimeMinutes,
    required this.byType,
    required this.bySeverity,
    required this.byDay,
  });

  factory AlertAnalytics.fromJson(Map<String, dynamic> json) => AlertAnalytics(
        total: (json['total'] as num).toInt(),
        critical: (json['critical'] as num).toInt(),
        high: (json['high'] as num).toInt(),
        medium: (json['medium'] as num).toInt(),
        low: (json['low'] as num).toInt(),
        unacknowledged: (json['unacknowledged'] as num).toInt(),
        averageResponseTimeMinutes:
            (json['average_response_time_minutes'] as num).toDouble(),
        byType: (json['by_type'] as List).cast<Map<String, dynamic>>(),
        bySeverity: (json['by_severity'] as List).cast<Map<String, dynamic>>(),
        byDay: (json['by_day'] as List).cast<Map<String, dynamic>>(),
      );
}

class HospitalOverview {
  final int totalHospitals;
  final int totalBeds;
  final int occupiedBeds;
  final List<HospitalMetrics> hospitals;

  const HospitalOverview({
    required this.totalHospitals,
    required this.totalBeds,
    required this.occupiedBeds,
    required this.hospitals,
  });

  factory HospitalOverview.fromJson(Map<String, dynamic> json) =>
      HospitalOverview(
        totalHospitals: (json['total_hospitals'] as num).toInt(),
        totalBeds: (json['total_beds'] as num).toInt(),
        occupiedBeds: (json['occupied_beds'] as num).toInt(),
        hospitals: (json['hospitals'] as List)
            .map((e) => HospitalMetrics.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class HospitalMetrics {
  final String id;
  final String name;
  final int patientCount;
  final int deviceCount;
  final int activeAlerts;
  final int bedCapacity;
  final double bedOccupancy;
  final List<Map<String, dynamic>> alertTrend;

  const HospitalMetrics({
    required this.id,
    required this.name,
    required this.patientCount,
    required this.deviceCount,
    required this.activeAlerts,
    required this.bedCapacity,
    required this.bedOccupancy,
    required this.alertTrend,
  });

  factory HospitalMetrics.fromJson(Map<String, dynamic> json) =>
      HospitalMetrics(
        id: json['id'] as String,
        name: json['name'] as String,
        patientCount: (json['patient_count'] as num).toInt(),
        deviceCount: (json['device_count'] as num).toInt(),
        activeAlerts: (json['active_alerts'] as num).toInt(),
        bedCapacity: (json['bed_capacity'] as num).toInt(),
        bedOccupancy: (json['bed_occupancy'] as num).toDouble(),
        alertTrend:
            (json['alert_trend'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      );
}

class SystemHealth {
  final int totalRequests24h;
  final int activeWebSockets;
  final double avgResponseTimeMs;
  final double errorRate24h;
  final int databaseConnections;
  final double cacheHitRate;
  final double uptimeHours;
  final List<Map<String, dynamic>> recentErrors;
  final List<Map<String, dynamic>> serviceStatus;

  const SystemHealth({
    required this.totalRequests24h,
    required this.activeWebSockets,
    required this.avgResponseTimeMs,
    required this.errorRate24h,
    required this.databaseConnections,
    required this.cacheHitRate,
    required this.uptimeHours,
    required this.recentErrors,
    required this.serviceStatus,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) => SystemHealth(
        totalRequests24h: (json['total_requests_24h'] as num).toInt(),
        activeWebSockets: (json['active_web_sockets'] as num).toInt(),
        avgResponseTimeMs: (json['avg_response_time_ms'] as num).toDouble(),
        errorRate24h: (json['error_rate_24h'] as num).toDouble(),
        databaseConnections: (json['database_connections'] as num).toInt(),
        cacheHitRate: (json['cache_hit_rate'] as num).toDouble(),
        uptimeHours: (json['uptime_hours'] as num).toDouble(),
        recentErrors:
            (json['recent_errors'] as List).cast<Map<String, dynamic>>(),
        serviceStatus:
            (json['service_status'] as List).cast<Map<String, dynamic>>(),
      );
}

class ActivityFeedItem {
  final String id;
  final String eventType;
  final String description;
  final String entityType;
  final String? entityId;
  final String? userName;
  final String timestamp;
  final Map<String, dynamic>? metadata;

  const ActivityFeedItem({
    required this.id,
    required this.eventType,
    required this.description,
    required this.entityType,
    this.entityId,
    this.userName,
    required this.timestamp,
    this.metadata,
  });

  factory ActivityFeedItem.fromJson(Map<String, dynamic> json) =>
      ActivityFeedItem(
        id: json['id'] as String,
        eventType: json['event_type'] as String,
        description: json['description'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String?,
        userName: json['user_name'] as String?,
        timestamp: json['timestamp'] as String,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}
