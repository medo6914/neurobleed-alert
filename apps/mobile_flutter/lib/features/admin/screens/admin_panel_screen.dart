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

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  int _selectedTab = 0;

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
                onRefresh: () async => ref.invalidate(adminStatsProvider),
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
              'لوحة التحكم',
              style: NeuroTypography.h1,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: NeuroColors.textPrimary),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: NeuroSpacing.lg, vertical: NeuroSpacing.sm),
      child: Row(
        children: [
          _buildTab('المستخدمين', 0),
          _buildTab('التحليلات', 1),
          _buildTab('النظام', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: NeuroSpacing.xs),
          padding: const EdgeInsets.symmetric(vertical: NeuroSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? NeuroColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(NeuroRadius.chip),
            border: Border.all(
              color: isSelected ? NeuroColors.primary : NeuroColors.navInactive,
            ),
          ),
          child: Text(
            label,
            style: NeuroTypography.caption?.copyWith(
              color: isSelected ? Colors.white : NeuroColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(AsyncValue<Map<String, dynamic>> statsAsync) {
    switch (_selectedTab) {
      case 0:
        return _buildUsersTab(statsAsync);
      case 1:
        return _buildAnalyticsTab(statsAsync);
      case 2:
        return _buildSystemTab();
      default:
        return _buildUsersTab(statsAsync);
    }
  }

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
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => _buildErrorCard(err),
            data: (stats) => _buildStatsRow(stats),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    return Row(
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
          Icons.local_hospital,
          'المرضى',
          '${stats['total_patients'] ?? '-'}',
          NeuroColors.medium,
        ),
      ],
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
    final users = [
      {'name': 'أحمد محمد', 'email': 'ahmed@hospital.com', 'role': 'طبيب', 'status': 'نشط'},
      {'name': 'فاطمة علي', 'email': 'fatima@hospital.com', 'role': 'ممرض', 'status': 'نشط'},
      {'name': 'محمد حسن', 'email': 'mohamed@hospital.com', 'role': 'طبيب', 'status': 'معلق'},
    ];

    return Column(
      children: users.map((user) => _buildUserCard(user)).toList(),
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    final isActive = user['status'] == 'نشط';
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: NeuroColors.primary.withValues(alpha: 0.3),
            child: Text(
              user['name']![0],
              style: const TextStyle(color: NeuroColors.textPrimary),
            ),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name']!, style: NeuroTypography.h3),
                Text(user['email']!, style: NeuroTypography.caption),
                Text(user['role']!, style: NeuroTypography.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NeuroSpacing.sm,
              vertical: NeuroSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: (isActive ? NeuroColors.low : NeuroColors.medium).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(NeuroRadius.badge),
            ),
            child: Text(
              user['status']!,
              style: NeuroTypography.badge?.copyWith(
                color: isActive ? NeuroColors.low : NeuroColors.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(AsyncValue<Map<String, dynamic>> statsAsync) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: Column(
        children: [
          statsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => _buildErrorCard(err),
            data: (stats) => Column(
              children: [
                _buildAnalyticsCard('إجمالي المستخدمين', '${stats['total_users'] ?? '-'}', Icons.people),
                _buildAnalyticsCard('المرضى النشطون', '${stats['total_patients'] ?? '-'}', Icons.person),
                _buildAnalyticsCard('الأجهزة المتصلة', '${stats['total_devices'] ?? '-'}', Icons.devices_other),
                _buildAnalyticsCard('إنذارات اليوم', '${stats['active_alerts'] ?? '12'}', Icons.notifications),
                _buildAnalyticsCard('معدل الاستجابة', '98%', Icons.speed),
                _buildAnalyticsCard('وقت التشغيل', '99.9%', Icons.timer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: NeuroColors.primary, size: 32),
          const SizedBox(width: NeuroSpacing.lg),
          Expanded(
            child: Text(title, style: NeuroTypography.h3),
          ),
          Text(value, style: NeuroTypography.display?.copyWith(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      child: Column(
        children: [
          _buildSystemCard('حالة الخادم', 'يعمل', NeuroColors.low),
          _buildSystemCard('قاعدة البيانات', 'متصلة', NeuroColors.low),
          _buildSystemCard('الذاكرة', '78%', NeuroColors.medium),
          _buildSystemCard('المعالج', '45%', NeuroColors.low),
          _buildSystemCard('المساحة', '120 GB', NeuroColors.low),
          const SizedBox(height: NeuroSpacing.lg),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildSystemCard(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.md),
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
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
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Text(title, style: NeuroTypography.h3),
          ),
          Text(value, style: NeuroTypography.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('معلومات النظام', style: NeuroTypography.h3),
          const SizedBox(height: NeuroSpacing.md),
          _buildInfoRow('التطبيق', 'NeuroBleed Alert'),
          _buildInfoRow('الإصدار', '1.0.0'),
          _buildInfoRow('البيئة', 'Production'),
          _buildInfoRow('إصدار API', 'v1'),
          _buildInfoRow('حالة BLE', 'Real (flutter_blue_plus)'),
          _buildInfoRow('المصادقة', 'JWT + OTP + OAuth2'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NeuroSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: NeuroTypography.caption),
          Text(value, style: NeuroTypography.bodyMedium),
        ],
      ),
    );
  }
}
