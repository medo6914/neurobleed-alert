import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../../core/auth/auth_provider.dart';

final dashboardDevicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response =
      await api.get('/v1/devices/', queryParameters: {'per_page': 50});
  final data = response.data;
  if (data is Map && data['items'] is List) return data['items'] as List;
  if (data is List) return data;
  return [];
});

final recentAlertsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api
      .get('/v1/alerts/', queryParameters: {'acknowledged': false, 'per_page': 5});
  final data = response.data;
  if (data is Map && data['items'] is List) return data['items'] as List;
  if (data is List) return data;
  return [];
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(dashboardDevicesProvider);
    final alertsAsync = ref.watch(recentAlertsProvider);

    return Scaffold(
      backgroundColor: NeuroColors.bgPrimary,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardDevicesProvider);
          ref.invalidate(recentAlertsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: NeuroSpacing.lg),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: NeuroSpacing.lg),
                  _buildDeviceCard(context, devicesAsync),
                  const SizedBox(height: NeuroSpacing.lg),
                  _buildBrainStateCard(context, alertsAsync),
                  const SizedBox(height: NeuroSpacing.lg),
                  _buildVitalSignsCard(context),
                  const SizedBox(height: NeuroSpacing.lg),
                  _buildEmergencyCard(context),
                  const SizedBox(height: NeuroSpacing.lg),
                  _buildQuickActions(context),
                  const SizedBox(height: NeuroSpacing.xl),
                ],
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
        NeuroSpacing.lg,
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  NeuroColors.primary.withValues(alpha: 0.4),
                  NeuroColors.bgPrimary,
                ],
              ),
            ),
            child: const Icon(
              Icons.psychology,
              color: NeuroColors.primaryLight,
              size: 28,
            ),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Neuro',
                        style: NeuroTypography.h2?.copyWith(
                          color: NeuroColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: 'Bleed',
                        style: NeuroTypography.h2?.copyWith(
                          color: NeuroColors.critical,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'دكاء اصطناعي لحماية دماغك',
                  style: NeuroTypography.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: NeuroColors.textPrimary),
            onPressed: () => context.go('/alerts'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
      BuildContext context, AsyncValue<List<dynamic>> devicesAsync) {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeuroColors.cardGradTop, NeuroColors.cardGradBottom],
        ),
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(
            color: NeuroColors.primary.withValues(alpha: 0.3)),
      ),
      child: devicesAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (err, _) => Row(
          children: [
            Icon(Icons.bluetooth_disabled,
                color: NeuroColors.navInactive, size: 20),
            const SizedBox(width: NeuroSpacing.sm),
            Text('تعذر الاتصال بالجهاز', style: NeuroTypography.bodyMedium),
          ],
        ),
        data: (devices) {
          final connected = devices.firstWhere(
            (d) {
              final s = (d['status'] as String?)?.toLowerCase();
              return s == 'online' || s == 'active' || s == 'connected';
            },
            orElse: () => null,
          );
          final deviceName = connected?['device_name'] ??
              connected?['serial_number'] ??
              'NBA-HEADBAND-01';
          final isConnected = connected != null;

          return Row(
            children: [
              Icon(
                Icons.bluetooth,
                color: isConnected ? NeuroColors.primary : NeuroColors.navInactive,
                size: 28,
              ),
              const SizedBox(width: NeuroSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'متصل بالجهاز' : 'غير متصل',
                      style: NeuroTypography.bodyMedium?.copyWith(
                        color: NeuroColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$deviceName',
                      style: NeuroTypography.caption?.copyWith(
                        color: NeuroColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: NeuroColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(NeuroRadius.md),
                ),
                child: Icon(
                  Icons.headset_mic,
                  color: NeuroColors.primaryLight,
                  size: 32,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrainStateCard(
      BuildContext context, AsyncValue<List<dynamic>> alertsAsync) {
    final hasCriticalAlert = alertsAsync.valueOrNull?.any((a) =>
            (a['severity'] as String?)?.toLowerCase() == 'critical') ??
        false;
    final riskPercent = hasCriticalAlert ? 78 : 18;
    final riskColor = hasCriticalAlert ? NeuroColors.critical : NeuroColors.low;
    final statusText = hasCriticalAlert ? 'حالة طارئة' : 'الحالة مستقرة';

    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeuroColors.cardGradTop, NeuroColors.cardGradBottom],
        ),
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'حالة الدماغ الآن',
                      style: NeuroTypography.h3?.copyWith(
                        color: NeuroColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: NeuroSpacing.sm),
                    Icon(Icons.show_chart,
                        color: NeuroColors.primaryLight, size: 18),
                  ],
                ),
                const SizedBox(height: NeuroSpacing.xl),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: riskPercent / 100,
                        strokeWidth: 10,
                        backgroundColor:
                            NeuroColors.textPrimary.withValues(alpha: 0.08),
                        valueColor:
                            AlwaysStoppedAnimation(riskColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$riskPercent%',
                          style: NeuroTypography.displayLarge?.copyWith(
                            fontSize: 32,
                            color: NeuroColors.textPrimary,
                          ),
                        ),
                        Text(
                          'احتمال النزيف',
                          style: NeuroTypography.caption?.copyWith(
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: NeuroSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NeuroSpacing.md,
                    vertical: NeuroSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(NeuroRadius.badge),
                    border: Border.all(color: riskColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasCriticalAlert
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: riskColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: NeuroTypography.badge?.copyWith(color: riskColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NeuroSpacing.lg),
          Expanded(
            flex: 1,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NeuroRadius.md),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    NeuroColors.primary.withValues(alpha: 0.2),
                    NeuroColors.bgPrimary,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.psychology,
                  size: 80,
                  color: NeuroColors.primaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSignsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeuroColors.cardGradTop, NeuroColors.cardGradBottom],
        ),
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المؤشرات الحيوية', style: NeuroTypography.h3),
          const SizedBox(height: NeuroSpacing.md),
          Row(
            children: [
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.water_drop_outlined,
                  label: 'تنشيع الأكسجين',
                  value: '96%',
                  color: NeuroColors.info,
                ),
              ),
              const SizedBox(width: NeuroSpacing.sm),
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.psychology_outlined,
                  label: 'تددفق الدم للدماغ',
                  value: '75%',
                  color: NeuroColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.favorite_outline,
                  label: 'معدل النبض',
                  value: '78 BPM',
                  color: NeuroColors.critical,
                ),
              ),
              const SizedBox(width: NeuroSpacing.sm),
              Expanded(
                child: _VitalSignTile(
                  icon: Icons.thermostat,
                  label: 'درجة الحرارة',
                  value: '36.6°C',
                  color: NeuroColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context),
      child: Container(
        padding: const EdgeInsets.all(NeuroSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              NeuroColors.critical.withValues(alpha: 0.2),
              NeuroColors.critical.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(NeuroRadius.card),
          border: Border.all(
              color: NeuroColors.critical.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NeuroColors.critical.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: NeuroColors.critical,
                size: 28,
              ),
            ),
            const SizedBox(width: NeuroSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة طارئة',
                    style: NeuroTypography.h3?.copyWith(
                      color: NeuroColors.criticalBright,
                    ),
                  ),
                  Text(
                    'اضغط إذا شعرت بأي أعراض خطرة',
                    style: NeuroTypography.caption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: NeuroColors.critical,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.phone,
            label: 'اتصال طوارئ',
            color: NeuroColors.critical,
            onTap: () => _showEmergencyDialog(context),
          ),
        ),
        const SizedBox(width: NeuroSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.local_hospital_outlined,
            label: 'أقرب مستشفى',
            color: NeuroColors.primary,
            onTap: () => context.go('/map'),
          ),
        ),
        const SizedBox(width: NeuroSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.share_location_outlined,
            label: 'مشاركة الموقع',
            color: NeuroColors.info,
            onTap: () => _shareLocation(context),
          ),
        ),
        const SizedBox(width: NeuroSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.description_outlined,
            label: 'سجل التقارير',
            color: NeuroColors.primaryLight,
            onTap: () => context.go('/reports'),
          ),
        ),
      ],
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: NeuroColors.critical),
            const SizedBox(width: 8),
            Text('اتصال طوارئ', style: NeuroTypography.h3),
          ],
        ),
        content: Text(
          'هل تريد الاتصال برقم الطوارئ (123)؟',
          style: NeuroTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('إلغاء', style: TextStyle(color: NeuroColors.navInactive)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse('tel:123');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeuroColors.critical,
              foregroundColor: Colors.white,
            ),
            child: const Text('اتصال'),
          ),
        ],
      ),
    );
  }

  void _shareLocation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري مشاركة الموقع...'),
        backgroundColor: NeuroColors.info,
      ),
    );
  }
}

class _VitalSignTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _VitalSignTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(NeuroRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: NeuroSpacing.sm),
          Text(
            label,
            style: NeuroTypography.caption?.copyWith(
              color: NeuroColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: NeuroTypography.h2?.copyWith(
              color: color,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: NeuroSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: NeuroTypography.caption?.copyWith(
                color: NeuroColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
