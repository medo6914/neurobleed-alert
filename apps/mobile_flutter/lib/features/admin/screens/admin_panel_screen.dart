import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// design_system removed — using inline colors for consistency
import 'package:core/core.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/overview');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminHospitalsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/hospitals');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminAlertsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/alerts');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminSystemHealthProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/system-health');
  return response.data is Map ? response.data as Map<String, dynamic> : {};
});

final adminActivityProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api
      .get('/v1/analytics/activity-feed', queryParameters: {'limit': 50});
  final data = response.data;
  if (data is List) return data;
  return [];
});

final adminDevicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response =
      await api.get('/v1/devices/', queryParameters: {'per_page': 50});
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
      backgroundColor: const Color(0xFF0A0E1A),
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
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 24),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const Text(
            'لوحة التحكم الإدارية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF42A5F5)
                      : const Color(0xFF2A2F45),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _tabs[index].$2,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _tabs[index].$1,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF8E8E93),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
            ),
            error: (err, _) => _buildErrorCard(err),
            data: (stats) => Row(
              children: [
                _buildStatCard(
                  Icons.people,
                  'إجمالي المستخدمين',
                  '${stats['total_users'] ?? '-'}',
                  const Color(0xFF2196F3),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  Icons.devices_other,
                  'الأجهزة',
                  '${stats['total_devices'] ?? '-'}',
                  const Color(0xFF34C759),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  Icons.person,
                  'المرضى',
                  '${stats['total_patients'] ?? '-'}',
                  const Color(0xFFFFCC00),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'المستخدمون',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddAdminDialog(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('إضافة مسؤول'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: const Color(0xFF8E8E93),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUserList(),
        ],
      ),
    );
  }

  Widget _buildErrorCard(Object err) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Color(0xFFFF3B30)),
          const SizedBox(height: 8),
          Text('تعذر تحميل الإحصائيات', style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text('$err', style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
          )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'بحث عن مستخدم...',
          hintStyle: TextStyle(color: Color(0xFF8E8E93)),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Color(0xFF8E8E93)),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
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
      loading: () => const Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
      error: (err, _) => _buildErrorCard(err),
      data: (items) {
        final users = items.where((i) {
          final t = (i['entity_type'] as String? ?? '').toLowerCase();
          return t.contains('user') || t.contains('auth');
        }).toList();
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, color: Colors.white.withValues(alpha: 0.3), size: 64),
                const SizedBox(height: 16),
                Text('لا توجد بيانات مستخدمين', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                const SizedBox(height: 8),
                Text('ستظهر أنشطة المستخدمين هنا', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
              ],
            ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2196F3).withValues(alpha: 0.3),
            child: Text(
              name.isNotEmpty ? name[0] : '؟',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                ), maxLines: 2),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(time),
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'نشط',
              style: TextStyle(color: Color(0xFF34C759), fontSize: 12),
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
      padding: const EdgeInsets.all(16),
      child: hospitalsAsync.when(
        loading: () => const Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
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
                  _buildStatCard(Icons.business, 'المستشفيات', '$total',
                      const Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      Icons.hotel, 'الأسرة', '$beds', const Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  _buildStatCard(Icons.meeting_room, 'مشغول', '$occupied',
                      const Color(0xFFFFCC00)),
                ],
              ),
              const SizedBox(height: 16),
              if (hospitals.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_hospital_outlined, color: Colors.white.withValues(alpha: 0.3), size: 64),
                      const SizedBox(height: 16),
                      Text('لا توجد مستشفيات', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('ستظهر المستشفيات هنا', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                    ],
                  ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: const Color(0xFF2196F3), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
              ),
              if (alerts is int && alerts > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$alerts تنبيه',
                    style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniMetric(Icons.person, 'المرضى', '$patients'),
              const SizedBox(width: 16),
              _buildMiniMetric(Icons.devices_other, 'الأجهزة', '$devices'),
              const SizedBox(width: 16),
              _buildMiniMetric(Icons.meeting_room, 'الإشغال',
                  '${(occupancy * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
          color: Color(0xFF8E8E93),
          fontSize: 10,
        )),
      ],
    );
  }

  // ─── Alerts Tab ────────────────────────────────────────────────
  Widget _buildAlertsTab() {
    final alertsAsync = ref.watch(adminAlertsProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: alertsAsync.when(
        loading: () => const Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
        error: (err, _) => _buildErrorCard(err),
        data: (data) {
          final severity = data['by_severity'] as List? ?? [];
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCard(Icons.notifications, 'إجمالي',
                      '${data['total'] ?? '-'}', const Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  _buildStatCard(Icons.error, 'حرج',
                      '${data['critical'] ?? '-'}', const Color(0xFFFF3B30)),
                  const SizedBox(width: 12),
                  _buildStatCard(Icons.pending, 'غير معالجة',
                      '${data['unacknowledged'] ?? '-'}', const Color(0xFFFF9500)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'التنبيهات حسب الخطورة',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 12),
              if (severity.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, color: Colors.white.withValues(alpha: 0.3), size: 64),
                      const SizedBox(height: 16),
                      Text('لا توجد بيانات تنبيهات', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('ستظهر إحصائيات التنبيهات هنا', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                    ],
                  ),
                )
              else
                ...severity.map((s) {
                  final label = s['severity'] as String? ?? 'غير معروف';
                  final count = s['count'] ?? 0;
                  final color = switch (label.toLowerCase()) {
                    'critical' => const Color(0xFFFF3B30),
                    'high' => const Color(0xFFFF9500),
                    'medium' => const Color(0xFFFFCC00),
                    _ => const Color(0xFF34C759),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ))),
          Text(value, style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          )),
        ],
      ),
    );
  }

  // ─── Analytics Tab ─────────────────────────────────────────────
  Widget _buildAnalyticsTab(AsyncValue<Map<String, dynamic>> statsAsync) {
    final patientsAsync = ref.watch(adminPatientsProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
            ),
            error: (err, _) => _buildErrorCard(err),
            data: (stats) => Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(Icons.people, 'مستخدمون',
                        '${stats['total_users'] ?? '-'}', const Color(0xFF2196F3)),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.person, 'مرضى',
                        '${stats['total_patients'] ?? '-'}', const Color(0xFF2196F3)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(Icons.devices_other, 'أجهزة',
                        '${stats['total_devices'] ?? '-'}', const Color(0xFF34C759)),
                    const SizedBox(width: 12),
                    _buildStatCard(Icons.notifications, 'إنذارات',
                        '${stats['total_alerts'] ?? '-'}', const Color(0xFFFFCC00)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                        Icons.description,
                        'تقارير',
                        '${stats['reports_generated'] ?? '-'}',
                        const Color(0xFFFF9500)),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        Icons.meeting_room,
                        'إشغال',
                        '${_percent(stats['bed_occupancy_rate'])}%',
                        const Color(0xFFFF3B30)Bright),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          patientsAsync.when(
            loading: () =>
                const SizedBox(height: 100, child: Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3)))),
            error: (err, _) => _buildErrorCard(err),
            data: (p) => Column(
              children: [
                _buildAnalyticsCard('إجمالي المرضى', '${p['total'] ?? '-'}',
                    Icons.person, const Color(0xFF2196F3)),
                _buildAnalyticsCard('مرضى نشطون', '${p['active'] ?? '-'}',
                    Icons.person_outline, const Color(0xFF34C759)),
                _buildAnalyticsCard(
                    'مقبولون اليوم',
                    '${p['admitted_today'] ?? '-'}',
                    Icons.arrow_downward,
                    const Color(0xFF2196F3)),
                _buildAnalyticsCard('متوسط العمر', _dec(p['average_age']),
                    Icons.cake_outlined, const Color(0xFFFFCC00)),
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

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ))),
          Text(value, style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          )),
        ],
      ),
    );
  }

  // ─── Devices Tab ───────────────────────────────────────────────
  Widget _buildDevicesTab() {
    final devicesAsync = ref.watch(adminDevicesProvider);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: devicesAsync.when(
        loading: () => const Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
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
                  _buildStatCard(Icons.devices_other, 'إجمالي',
                      '${devices.length}', const Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      Icons.wifi, 'متصل', '$online', const Color(0xFF34C759)),
                ],
              ),
              const SizedBox(height: 16),
              if (devices.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sensors_off, color: Colors.white.withValues(alpha: 0.3), size: 64),
                      const SizedBox(height: 16),
                      Text('لا توجد أجهزة', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('ستظهر الأجهزة المسجلة هنا', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                    ],
                  ),
                )
              else
                ...devices.map((d) {
                  final name = d['device_name'] ?? d['serial_number'] ?? 'جهاز';
                  final status =
                      (d['status'] as String? ?? 'offline').toLowerCase();
                  final battery = (d['battery_level'] as num?)?.toDouble();
                  final isOnline = status == 'online' ||
                      status == 'active' ||
                      status == 'connected';
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (online ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sensors,
              color: online ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
                if (serial.isNotEmpty)
                  Text('SN: $serial', style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 10,
                  )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                online ? 'متصل' : 'غير متصل',
                style: TextStyle(
                  color: online ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  fontSize: 12,
                ),
              ),
              if (battery != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${battery.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: battery < 20
                        ? const Color(0xFFFF3B30)
                        : const Color(0xFF8E8E93),
                    fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      child: activityAsync.when(
        loading: () => const Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
        error: (err, _) => _buildErrorCard(err),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: Colors.white.withValues(alpha: 0.3), size: 64),
                  const SizedBox(height: 16),
                  Text('لا توجد سجلات تدقيق', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('ستظهر جميع أنشطة النظام هنا', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                ],
              ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_eventIcon(type), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc.isNotEmpty ? desc : type.replaceAll('_', ' '),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                ),
                if (user.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user, style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 10,
                  )),
                ],
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_formatTime(time), style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 10,
                  )),
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
    if (t.contains('alert') || t.contains('error')) return const Color(0xFFFF3B30);
    if (t.contains('device')) return const Color(0xFF2196F3);
    if (t.contains('patient')) return const Color(0xFF2196F3);
    if (t.contains('auth') || t.contains('login')) return const Color(0xFFFFCC00);
    if (t.contains('report')) return const Color(0xFFFF9500);
    if (t.contains('ai')) return const Color(0xFF34C759);
    return const Color(0xFF8E8E93);
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          aiAsync.when(
            loading: () =>
                const SizedBox(height: 120, child: Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3)))),
            error: (err, _) => _buildErrorCard(err),
            data: (health) => Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1F35),
                        const Color(0xFF0D1220)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.psychology,
                          size: 56, color: const Color(0xFF2196F3)Light),
                      const SizedBox(height: 12),
                      Text(
                        health['status'] == 'ok'
                            ? 'الخدمة تعمل'
                            : 'خدمة غير متاحة',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)?.copyWith(
                          color: health['status'] == 'ok'
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إصدار النموذج: ${health['model_version'] ?? '-'}',
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildAiStatusChip(
                              'النموذج', health['model_trained'] == true),
                          const SizedBox(width: 8),
                          _buildAiStatusChip(
                              'القواعد', health['rules_loaded'] == true),
                          const SizedBox(width: 8),
                          _buildAiStatusChip(
                              'RAG', health['rag_loaded'] == true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('نشاط محرك الذكاء الاصطناعي', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
              ],
            ),
          ),
          activityAsync.when(
            loading: () =>
                const SizedBox(height: 80, child: Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3)))),
            error: (err, _) => _buildErrorCard(err),
            data: (items) {
              final aiItems = items.where((i) {
                final t = (i['event_type'] as String? ?? '').toLowerCase();
                return t.contains('ai') ||
                    t.contains('risk') ||
                    t.contains('report');
              }).toList();
              final display = aiItems.isEmpty
                  ? items.take(10).toList()
                  : aiItems.take(10).toList();
              if (display.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology_outlined, color: Colors.white.withValues(alpha: 0.3), size: 64),
                      const SizedBox(height: 16),
                      Text('لا توجد سجلات AI', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('ستظهر أنشطة محرك الذكاء الاصطناعي هنا', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
                    ],
                  ),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: (ok ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (ok ? const Color(0xFF34C759) : const Color(0xFFFF3B30))
                .withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: ok ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 10,
              ),
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
      padding: const EdgeInsets.all(16),
      child: healthAsync.when(
        loading: () => const Center(child: const CircularProgressIndicator(color: Color(0xFF2196F3))),
        error: (err, _) => _buildErrorCard(err),
        data: (data) {
          final services = data['service_status'] as List? ?? [];
          final errors = data['recent_errors'] as List? ?? [];
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                      Icons.speed,
                      'متوسط الاستجابة',
                      '${data['avg_response_time_ms'] ?? '-'}ms',
                      const Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      Icons.error_outline,
                      'معدل الخطأ',
                      '${_percent(data['error_rate_24h'])}%',
                      const Color(0xFFFF3B30)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(
                      Icons.timer,
                      'وقت التشغيل',
                      '${(data['uptime_hours'] as num?)?.toStringAsFixed(0) ?? '-'}h',
                      const Color(0xFF34C759)),
                  const SizedBox(width: 12),
                  _buildStatCard(
                      Icons.cloud_done,
                      'الطلبات (24h)',
                      '${data['total_requests_24h'] ?? '-'}',
                      const Color(0xFFFFCC00)),
                ],
              ),
              const SizedBox(height: 16),
              if (services.isNotEmpty) ...[
                Text('حالة الخدمات', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...services.map((s) {
                  final name = s['service'] ?? s['name'] ?? 'خدمة';
                  final status =
                      (s['status'] as String? ?? 'unknown').toLowerCase();
                  final ok =
                      status == 'ok' || status == 'healthy' || status == 'up';
                  return _buildSystemRow('$name', ok ? 'يعمل' : status,
                      ok ? const Color(0xFF34C759) : const Color(0xFFFF3B30));
                }),
                const SizedBox(height: 16),
              ],
              if (errors.isNotEmpty) ...[
                Text('أحدث الأخطاء', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...errors.take(5).map((e) {
                  final msg = e['message'] ?? e['error'] ?? '$e';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.2)),
                    ),
                    child: Text('$msg', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ))),
          Text(value, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddAdminDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: const Text('إضافة مسؤول جديد', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'الاسم',
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final name = nameController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              try {
                final api = ref.read(apiClientProvider);
                await api.post('/v1/auth/promote-to-admin', data: {
                  'email': email,
                  if (name.isNotEmpty) 'name': name,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة المسؤول بنجاح'),
                      backgroundColor: Color(0xFF34C759),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل: $e'),
                      backgroundColor: const Color(0xFFFF3B30),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
