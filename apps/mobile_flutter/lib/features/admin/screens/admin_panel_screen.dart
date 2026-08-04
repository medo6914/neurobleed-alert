import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/overview');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminHospitalsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/hospitals');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminAlertsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/alerts');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminSystemHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/system-health');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminActivityProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/activity-feed', queryParameters: {'limit': 50});
  final data = response.data;
  if (data is List) return data;
  return [];
});

final adminDevicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/devices/', queryParameters: {'per_page': 50});
  final data = response.data;
  if (data is Map && data['items'] is List) return data['items'] as List;
  if (data is List) return data;
  return [];
});

final adminAiHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/ai/health');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminPatientsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/patients');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    ('المستخدمون', Icons.people_outline),
    ('المستشفيات', Icons.local_hospital_outlined),
    ('التنبيهات', Icons.notifications_none),
    ('التحليلات', Icons.insights),
    ('الأجهزة', Icons.devices_other),
    ('سجلات التدقيق', Icons.history),
    ('سجلات AI', Icons.psychology_outlined),
    ('صحة النظام', Icons.monitor_heart_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: NeuroColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminStatsProvider);
                  ref.invalidate(adminHospitalsProvider);
                  ref.invalidate(adminAlertsProvider);
                  ref.invalidate(adminSystemHealthProvider);
                  ref.invalidate(adminActivityProvider);
                  ref.invalidate(adminDevicesProvider);
                  ref.invalidate(adminAiHealthProvider);
                  ref.invalidate(adminPatientsProvider);
                },
                child: _buildTabContent(statsAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        NeuroSpacing.lg,
        MediaQuery.of(context).padding.top + NeuroSpacing.sm,
        NeuroSpacing.lg,
        NeuroSpacing.sm,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NeuroColors.headerGradTop, NeuroColors.headerGradBottom],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: NeuroColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'لوحة التحكم الإدارية',
              style: NeuroTypography.h1,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: NeuroColors.textPrimary),
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(adminHospitalsProvider);
              ref.invalidate(adminAlertsProvider);
              ref.invalidate(adminSystemHealthProvider);
              ref.invalidate(adminActivityProvider);
              ref.invalidate(adminDevicesProvider);
              ref.invalidate(adminAiHealthProvider);
              ref.invalidate(adminPatientsProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: NeuroSpacing.sm, vertical: NeuroSpacing.sm),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: NeuroSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: NeuroSpacing.md),
              decoration: BoxDecoration(
                color: isSelected ? NeuroColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(NeuroRadius.chip),
                border: Border.all(
                  color: isSelected ? NeuroColors.primary : NeuroColors.navInactive,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _tabs[index].$2,
                    size: 16,
                    color: isSelected ? NeuroColors.textPrimary : NeuroColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _tabs[index].$1,
                    style: NeuroTypography.caption?.copyWith(
                      color: isSelected ? NeuroColors.textPrimary : NeuroColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(AsyncValue<Map<String, dynamic>> statsAsync) {
    switch (_selectedTab) {
      case 0:
        return _buildUsersTab(statsAsync);
      case 1:
        return _buildHospitalsTab();
      case 2:
        return _buildAlertsTab();
      case 3:
        return _buildAnalyticsTab(statsAsync);
      case 4:
        return _buildDevicesTab();
      case 5:
        return _buildAuditTab();
      case 6:
        return _buildAiLogsTab();
      case 7:
        return _buildSystemHealthTab();
      default:
        return _buildUsersTab(statsAsync);
    }
  }

  // ─── Users Tab ─────────────────────────────────────────────────
  Widget _buildUsersTab(AsyncValue<Map<String, dynamic>> statsAsync) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: NeuroSpacing.lg),
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: AppLoading()),
            ),
            error: (err, _) => _buildErrorCard(err),
            data: (stats) => Row(
              children: [
                _buildStatCard(
                  Icons.people,
                  'إجمالي المستخدمين',
                  '${stats['total_users'] ?? '-'}',
                  NeuroColors.primary,
                ),
                const SizedBox(width: NeuroSpacing.md),
                _buildStatCard(
                  Icons.devices_other,
                  'الأجهزة',
                  '${stats['total_devices'] ?? '-'}',
                  NeuroColors.low,
                ),
                const SizedBox(width: NeuroSpacing.md),
                _buildStatCard(
                  Icons.person,
                  'المرضى',
                  '${stats['total_patients'] ?? '-'}',
                  NeuroColors.medium,
                ),
              ],
            ),
          ),
          const SizedBox(height: NeuroSpacing.lg),
          _buildUserList(),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object err) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: NeuroColors.critical.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: NeuroColors.critical),
          const SizedBox(height: 8),
          Text('تعذر تحميل الإحصائيات', style: NeuroTypography.bodyMedium),
          const SizedBox(height: 4),
          Text('$err', style: NeuroTypography.caption),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgInput,
        borderRadius: BorderRadius.circular(NeuroRadius.input),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'بحث عن مستخدم...',
          hintStyle: TextStyle(color: NeuroColors.navInactive),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: NeuroColors.navInactive),
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(NeuroSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(NeuroRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: NeuroSpacing.sm),
            Text(
              value,
              style: NeuroTypography.display?.copyWith(fontSize: 24, color: color),
            ),
            const SizedBox(height: NeuroSpacing.xs),
            Text(
              label,
              style: NeuroTypography.caption?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    final activityAsync = ref.watch(adminActivityProvider);
    return activityAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (err, _) => _buildErrorCard(err),
      data: (items) {
        final users = items.where((i) {
          final t = (i['entity_type'] as String? ?? '').toLowerCase();
          return t.contains('user') || t.contains('auth');
        }).toList();
        if (users.isEmpty) {
          return const AppEmptyState(
            icon: Icons.people_outline,
            title: 'لا توجد بيانات مستخدمين',
            message: 'ستظهر أنشطة المستخدمين هنا',
          );
        }
        return Column(
          children: users.take(8).map((item) {
            return _buildUserCard(
              item['user_name'] as String? ?? 'مستخدم',
              '${item['event_type']} · ${item['description']}',
              item['timestamp'] as String? ?? '',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserCard(String name, String detail, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: NeuroColors.primary.withValues(alpha: 0.3),
            child: Text(
              name.isNotEmpty ? name[0] : '؟',
              style: const TextStyle(color: NeuroColors.textPrimary),
            ),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: NeuroTypography.h3),
                const SizedBox(height: 2),
                Text(detail, style: NeuroTypography.caption, maxLines: 2),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(time),
                    style: NeuroTypography.caption?.copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NeuroSpacing.sm,
              vertical: NeuroSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: NeuroColors.low.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(NeuroRadius.badge),
            ),
            child: Text(
              'نشط',
              style: NeuroTypography.badge?.copyWith(color: NeuroColors.low),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hospitals Tab ─────────────────────────────────────────────
  Widget _buildHospitalsTab() {
    final hospitalsAsync = ref.watch(adminHospitalsProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: hospitalsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (err, _) => _buildErrorCard(err),
        data: (data) {
          final total = data['total_hospitals'] ?? 0;
          final beds = data['total_beds'] ?? 0;
          final occupied = data['occupied_beds'] ?? 0;
          final hospitals = (data['hospitals'] as List? ?? []);
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCard(Icons.business, 'المستشفيات', '$total', NeuroColors.primary),
                  const SizedBox(width: NeuroSpacing.md),
                  _buildStatCard(Icons.hotel, 'الأسرة', '$beds', NeuroColors.info),
                  const SizedBox(width: NeuroSpacing.md),
                  _buildStatCard(Icons.meeting_room, 'مشغول', '$occupied', NeuroColors.medium),
                ],
              ),
              const SizedBox(height: NeuroSpacing.lg),
              if (hospitals.isEmpty)
                const AppEmptyState(
                  icon: Icons.local_hospital_outlined,
                  title: 'لا توجد مستشفيات',
                  message: 'ستظهر المستشفيات هنا',
                )
              else
                ...hospitals.map((h) => _buildHospitalCard(h)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHospitalCard(dynamic h) {
    final name = h['name'] as String? ?? 'مستشفى';
    final patients = h['patient_count'] ?? '-';
    final devices = h['device_count'] ?? '-';
    final alerts = h['active_alerts'] ?? 0;
    final occupancy = (h['bed_occupancy'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: NeuroColors.primary, size: 32),
              const SizedBox(width: NeuroSpacing.md),
              Expanded(
                child: Text(name, style: NeuroTypography.h3),
              ),
              if (alerts is int && alerts > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NeuroSpacing.sm,
                    vertical: NeuroSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: NeuroColors.critical.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(NeuroRadius.badge),
                  ),
                  child: Text(
                    '$alerts تنبيه',
                    style: NeuroTypography.badge?.copyWith(color: NeuroColors.critical),
                  ),
                ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.md),
          Row(
            children: [
              _buildMiniMetric(Icons.person, 'المرضى', '$patients'),
              const SizedBox(width: NeuroSpacing.lg),
              _buildMiniMetric(Icons.devices_other, 'الأجهزة', '$devices'),
              const SizedBox(width: NeuroSpacing.lg),
              _buildMiniMetric(Icons.meeting_room, 'الإشغال', '${(occupancy * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: NeuroColors.textSecondary),
        const SizedBox(width: 4),
        Text(value, style: NeuroTypography.h3?.copyWith(fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: NeuroTypography.caption?.copyWith(fontSize: 10)),
      ],
    );
  }

  // ─── Alerts Tab ────────────────────────────────────────────────
  Widget _buildAlertsTab() {
    final alertsAsync = ref.watch(adminAlertsProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: alertsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (err, _) => _buildErrorCard(err),
        data: (data) {
          final severity = data['by_severity'] as List? ?? [];
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCard(Icons.notifications, 'إجمالي', '${data['total'] ?? '-'}', NeuroColors.primary),
                  const SizedBox(width: NeuroSpacing.md),
                  _buildStatCard(Icons.error, 'حرج', '${data['critical'] ?? '-'}', NeuroColors.critical),
                  const SizedBox(width: NeuroSpacing.md),
                  _buildStatCard(Icons.pending, 'غير معالجة', '${data['unacknowledged'] ?? '-'}', NeuroColors.high),
                ],
              ),
              const SizedBox(height: NeuroSpacing.lg),
              Text(
                'التنبيهات حسب الخطورة',
                style: NeuroTypography.h2,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: NeuroSpacing.md),
              if (severity.isEmpty)
                const AppEmptyState(
                  icon: Icons.notifications_none,
                  title: 'لا توجد بيانات تنبيهات',
                  message: 'ستظهر إحصائيات التنبيهات هنا',
                )
              else
                ...severity.map((s) {
                  final label = s['severity'] as String? ?? 'غير معروف';
                  final count = s['count'] ?? 0;
                  final color = switch (label.toLowerCase()) {
                    'critical' => NeuroColors.critical,
                    'high' => NeuroColors.high,
                    'medium' => NeuroColors.medium,
                    _ => NeuroColors.low,
                  };
                  return _buildMetricRow(
                    icon: Icons.warning_amber_rounded,
                    label: _severityLabel(label),
                    value: '$count',
                    color: color,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  String _severityLabel(String s) {
    return switch (s.toLowerCase()) {
      'critical' => 'حرج',
      'high' => 'مرتفع',
      'medium' => 'متوسط',
      'low' => 'منخفض',
      _ => s,
    };
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: NeuroSpacing.lg),
          Expanded(child: Text(label, style: NeuroTypography.h3)),
          Text(value, style: NeuroTypography.display?.copyWith(fontSize: 24, color: color)),
        ],
      ),
    );
  }

  // ─── Analytics Tab ─────────────────────────────────────────────
  Widget _buildAnalyticsTab(AsyncValue<Map<String, dynamic>> statsAsync) {
    final patientsAsync = ref.watch(adminPatientsProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: Column(
        children: [
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: AppLoading()),
            ),
            error: (err, _) => _buildErrorCard(err),
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(Icons.people, 'مستخدمون', '${stats['total_users'] ?? '-'}', NeuroColors.primary),
                    const SizedBox(width: NeuroSpacing.md),
                    _buildStatCard(Icons.person, 'مرضى', '${stats['total_patients'] ?? '-'}', NeuroColors.info),
                  ],
                ),
                const SizedBox(height: NeuroSpacing.md),
                Row(
                  children: [
                    _buildStatCard(Icons.devices_other, 'أجهزة', '${stats['total_devices'] ?? '-'}', NeuroColors.low),
                    const SizedBox(width: NeuroSpacing.md),
                    _buildStatCard(Icons.notifications, 'إنذارات', '${stats['total_alerts'] ?? '-'}', NeuroColors.medium),
                  ],
                ),
                const SizedBox(height: NeuroSpacing.md),
                Row(
                  children: [
                    _buildStatCard(Icons.description, 'تقارير', '${stats['reports_generated'] ?? '-'}', NeuroColors.high),
                    const SizedBox(width: NeuroSpacing.md),
                    _buildStatCard(Icons.meeting_room, 'إشغال', '${_percent(stats['bed_occupancy_rate'])}%', NeuroColors.criticalBright),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: NeuroSpacing.lg),
          patientsAsync.when(
            loading: () => const SizedBox(height: 100, child: Center(child: AppLoading())),
            error: (err, _) => _buildErrorCard(err),
            data: (p) => Column(
              children: [
                _buildAnalyticsCard('إجمالي المرضى', '${p['total'] ?? '-'}', Icons.person, NeuroColors.primary),
                _buildAnalyticsCard('مرضى نشطون', '${p['active'] ?? '-'}', Icons.person_outline, NeuroColors.low),
                _buildAnalyticsCard('مقبولون اليوم', '${p['admitted_today'] ?? '-'}', Icons.arrow_downward, NeuroColors.info),
                _buildAnalyticsCard('متوسط العمر', _dec(p['average_age']), Icons.cake_outlined, NeuroColors.medium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _percent(dynamic v) {
    final n = (v as num?)?.toDouble();
    return n == null ? '-' : (n * 100).toStringAsFixed(0);
  }

  String _dec(dynamic v) {
    final n = (v as num?)?.toDouble();
    return n == null ? '-' : n.toStringAsFixed(1);
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: NeuroSpacing.lg),
          Expanded(child: Text(title, style: NeuroTypography.h3)),
          Text(value, style: NeuroTypography.display?.copyWith(fontSize: 24, color: color)),
        ],
      ),
    );
  }

  // ─── Devices Tab ───────────────────────────────────────────────
  Widget _buildDevicesTab() {
    final devicesAsync = ref.watch(adminDevicesProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: devicesAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (err, _) => _buildErrorCard(err),
        data: (devices) {
          final online = devices.where((d) {
            final s = (d['status'] as String? ?? '').toLowerCase();
            return s == 'online' || s == 'active' || s == 'connected';
          }).length;
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCard(Icons.devices_other, 'إجمالي', '${devices.length}', NeuroColors.primary),
                  const SizedBox(width: NeuroSpacing.md),
                  _buildStatCard(Icons.wifi, 'متصل', '$online', NeuroColors.low),
                ],
              ),
              const SizedBox(height: NeuroSpacing.lg),
              if (devices.isEmpty)
                const AppEmptyState(
                  icon: Icons.sensors_off,
                  title: 'لا توجد أجهزة',
                  message: 'ستظهر الأجهزة المسجلة هنا',
                )
              else
                ...devices.map((d) {
                  final name = d['device_name'] ?? d['serial_number'] ?? 'جهاز';
                  final status = (d['status'] as String? ?? 'offline').toLowerCase();
                  final battery = (d['battery_level'] as num?)?.toDouble();
                  final isOnline = status == 'online' || status == 'active' || status == 'connected';
                  return _buildDeviceCard(
                    name: '$name',
                    serial: d['serial_number'] as String? ?? '',
                    online: isOnline,
                    battery: battery,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceCard({
    required String name,
    required String serial,
    required bool online,
    double? battery,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (online ? NeuroColors.low : NeuroColors.critical).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(NeuroRadius.md),
            ),
            child: Icon(
              Icons.sensors,
              color: online ? NeuroColors.low : NeuroColors.critical,
              size: 24,
            ),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: NeuroTypography.h3),
                if (serial.isNotEmpty)
                  Text('SN: $serial', style: NeuroTypography.caption?.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                online ? 'متصل' : 'غير متصل',
                style: NeuroTypography.badge?.copyWith(
                  color: online ? NeuroColors.low : NeuroColors.critical,
                ),
              ),
              if (battery != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${battery.toStringAsFixed(0)}%',
                  style: NeuroTypography.caption?.copyWith(
                    color: battery < 20 ? NeuroColors.critical : NeuroColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Audit Logs Tab ────────────────────────────────────────────
  Widget _buildAuditTab() {
    final activityAsync = ref.watch(adminActivityProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: activityAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (err, _) => _buildErrorCard(err),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history,
              title: 'لا توجد سجلات تدقيق',
              message: 'ستظهر جميع أنشطة النظام هنا',
            );
          }
          return Column(
            children: items.take(30).map((item) {
              return _buildAuditTile(item);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildAuditTile(dynamic item) {
    final type = item['event_type'] as String? ?? 'event';
    final desc = item['description'] as String? ?? '';
    final user = item['user_name'] as String? ?? '';
    final time = item['timestamp'] as String? ?? '';
    final color = _eventColor(type);
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.sm),
      padding: const EdgeInsets.all(NeuroSpacing.md),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.md),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(NeuroRadius.sm),
            ),
            child: Icon(_eventIcon(type), size: 18, color: color),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc.isNotEmpty ? desc : type.replaceAll('_', ' '),
                  style: NeuroTypography.bodyMedium,
                  maxLines: 2,
                ),
                if (user.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user, style: NeuroTypography.caption?.copyWith(fontSize: 10)),
                ],
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_formatTime(time), style: NeuroTypography.caption?.copyWith(fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('alert')) return Icons.warning_amber_rounded;
    if (t.contains('device')) return Icons.sensors;
    if (t.contains('patient')) return Icons.person;
    if (t.contains('auth') || t.contains('login')) return Icons.lock_outline;
    if (t.contains('report')) return Icons.description_outlined;
    if (t.contains('ai')) return Icons.psychology_outlined;
    return Icons.circle_outlined;
  }

  Color _eventColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('alert') || t.contains('error')) return NeuroColors.critical;
    if (t.contains('device')) return NeuroColors.info;
    if (t.contains('patient')) return NeuroColors.primary;
    if (t.contains('auth') || t.contains('login')) return NeuroColors.medium;
    if (t.contains('report')) return NeuroColors.high;
    if (t.contains('ai')) return NeuroColors.low;
    return NeuroColors.textSecondary;
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.length > 16 ? iso.substring(0, 16) : iso;
    }
  }

  // ─── AI Logs Tab ───────────────────────────────────────────────
  Widget _buildAiLogsTab() {
    final aiAsync = ref.watch(adminAiHealthProvider);
    final activityAsync = ref.watch(adminActivityProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: Column(
        children: [
          aiAsync.when(
            loading: () => const SizedBox(height: 120, child: Center(child: AppLoading())),
            error: (err, _) => _buildErrorCard(err),
            data: (health) => Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(NeuroSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [NeuroColors.cardGradTop, NeuroColors.cardGradBottom],
                    ),
                    borderRadius: BorderRadius.circular(NeuroRadius.card),
                    boxShadow: const [NeuroShadows.card],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.psychology, size: 56, color: NeuroColors.primaryLight),
                      const SizedBox(height: NeuroSpacing.md),
                      Text(
                        health['status'] == 'ok' ? 'الخدمة تعمل' : 'خدمة غير متاحة',
                        style: NeuroTypography.h2?.copyWith(
                          color: health['status'] == 'ok' ? NeuroColors.low : NeuroColors.critical,
                        ),
                      ),
                      const SizedBox(height: NeuroSpacing.sm),
                      Text(
                        'إصدار النموذج: ${health['model_version'] ?? '-'}',
                        style: NeuroTypography.caption,
                      ),
                      const SizedBox(height: NeuroSpacing.md),
                      Row(
                        children: [
                          _buildAiStatusChip('النموذج', health['model_trained'] == true),
                          const SizedBox(width: NeuroSpacing.sm),
                          _buildAiStatusChip('القواعد', health['rules_loaded'] == true),
                          const SizedBox(width: NeuroSpacing.sm),
                          _buildAiStatusChip('RAG', health['rag_loaded'] == true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NeuroSpacing.lg),
                Text('نشاط محرك الذكاء الاصطناعي', style: NeuroTypography.h2),
                const SizedBox(height: NeuroSpacing.md),
              ],
            ),
          ),
          activityAsync.when(
            loading: () => const SizedBox(height: 80, child: Center(child: AppLoading())),
            error: (err, _) => _buildErrorCard(err),
            data: (items) {
              final aiItems = items.where((i) {
                final t = (i['event_type'] as String? ?? '').toLowerCase();
                return t.contains('ai') || t.contains('risk') || t.contains('report');
              }).toList();
              final display = aiItems.isEmpty ? items.take(10).toList() : aiItems.take(10).toList();
              if (display.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.psychology_outlined,
                  title: 'لا توجد سجلات AI',
                  message: 'ستظهر أنشطة محرك الذكاء الاصطناعي هنا',
                );
              }
              return Column(
                children: display.map((item) => _buildAuditTile(item)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiStatusChip(String label, bool ok) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: NeuroSpacing.sm),
        decoration: BoxDecoration(
          color: (ok ? NeuroColors.low : NeuroColors.critical).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          border: Border.all(
            color: (ok ? NeuroColors.low : NeuroColors.critical).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: ok ? NeuroColors.low : NeuroColors.critical,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: NeuroTypography.caption?.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── System Health Tab ─────────────────────────────────────────
  Widget _buildSystemHealthTab() {
    final healthAsync = ref.watch(adminSystemHealthProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: healthAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (err, _) => _buildErrorCard(err),
        data: (data) {
          final services = data['service_status'] as List? ?? [];
          final errors = data['recent_errors'] as List? ?? [];
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCard(Icons.speed, 'متوسط الاستجابة', '${data['avg_response_time_ms'] ?? '-'}ms', NeuroColors.info),
                  const SizedBox(width: NeuroSpacing.md),
                  _buildStatCard(Icons.error_outline, 'معدل الخطأ', '${_percent(data['error_rate_24h'])}%', NeuroColors.critical),
                ],
              ),
              const SizedBox(height: NeuroSpacing.md),
              Row(
                children: [
                  _buildStatCard(Icons.timer, 'وقت التشغيل', '${(data['uptime_hours'] as num?)?.toStringAsFixed(0) ?? '-'}h', NeuroColors.low),
                  const SizedBox(width: NeuroSpacing.md),
                  _buildStatCard(Icons.cloud_done, 'الطلبات (24h)', '${data['total_requests_24h'] ?? '-'}', NeuroColors.medium),
                ],
              ),
              const SizedBox(height: NeuroSpacing.lg),
              if (services.isNotEmpty) ...[
                Text('حالة الخدمات', style: NeuroTypography.h2),
                const SizedBox(height: NeuroSpacing.md),
                ...services.map((s) {
                  final name = s['service'] ?? s['name'] ?? 'خدمة';
                  final status = (s['status'] as String? ?? 'unknown').toLowerCase();
                  final ok = status == 'ok' || status == 'healthy' || status == 'up';
                  return _buildSystemRow('$name', ok ? 'يعمل' : status, ok ? NeuroColors.low : NeuroColors.critical);
                }),
                const SizedBox(height: NeuroSpacing.lg),
              ],
              if (errors.isNotEmpty) ...[
                Text('أحدث الأخطاء', style: NeuroTypography.h2),
                const SizedBox(height: NeuroSpacing.md),
                ...errors.take(5).map((e) {
                  final msg = e['message'] ?? e['error'] ?? '$e';
                  return Container(
                    margin: const EdgeInsets.only(bottom: NeuroSpacing.sm),
                    padding: const EdgeInsets.all(NeuroSpacing.md),
                    decoration: BoxDecoration(
                      color: NeuroColors.critical.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(NeuroRadius.md),
                      border: Border.all(color: NeuroColors.critical.withValues(alpha: 0.2)),
                    ),
                    child: Text('$msg', style: NeuroTypography.caption),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemRow(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(child: Text(title, style: NeuroTypography.h3)),
          Text(value, style: NeuroTypography.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
