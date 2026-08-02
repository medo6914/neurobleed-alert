import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

import 'package:core/core.dart';
import '../../core/auth/auth_provider.dart';

final patientsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/patients/');
  return response.data as List;
});

final recentAlertsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/alerts/?acknowledged=false&per_page=5');
  return response.data as List;
});

final dashboardDevicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/devices/', queryParameters: {'per_page': 50});
  final data = response.data;
  if (data is Map && data['items'] is List) return data['items'] as List;
  if (data is List) return data;
  return [];
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsProvider);
    final alertsAsync = ref.watch(recentAlertsProvider);
    final devicesAsync = ref.watch(dashboardDevicesProvider);
    ref.watch(authStateProvider);

    final patientCount = patientsAsync.value?.length ?? 0;
    final alertCount = alertsAsync.value?.length ?? 0;
    final stableCount = patientsAsync.value
            ?.where((p) {
              final level = (p['risk_level'] as String?)?.toLowerCase();
              return level == null || level == 'low' || level == 'stable';
            })
            .length ??
        0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(patientsProvider);
          ref.invalidate(recentAlertsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildGlassHeader(
                context,
                patientCount: patientCount,
                alertCount: alertCount,
                stableCount: stableCount,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(NeuroSpacing.lg),
              sliver: SliverList.list(
                children: [
                  _buildQuickActions(context, patientsAsync),
                  const SizedBox(height: NeuroSpacing.xl),
                  _buildDeviceStatusCard(context, ref, devicesAsync),
                  const SizedBox(height: NeuroSpacing.xl),
                  _buildSectionHeader(context, 'المرضى النشطون', () {
                    context.go('/patients');
                  }),
                  const SizedBox(height: NeuroSpacing.md),
                  ..._buildPatientCards(context, ref, patientsAsync),
                  const SizedBox(height: NeuroSpacing.xl),
                  _buildSectionHeader(context, 'آخر الإنذارات', () {
                    context.go('/alerts');
                  }),
                  const SizedBox(height: NeuroSpacing.md),
                  ..._buildAlertTiles(context, ref, alertsAsync),
                  const SizedBox(height: NeuroSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Glassmorphism Header ─────────────────────────────────────────
  Widget _buildGlassHeader(
    BuildContext context, {
    required int patientCount,
    required int alertCount,
    required int stableCount,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        NeuroSpacing.lg,
        MediaQuery.of(context).padding.top + NeuroSpacing.lg,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NeuroBleed Alert',
                    style: NeuroTypography.h3?.copyWith(
                      color: NeuroColors.textSecondary,
                    ),
                  ),
                  Text(
                    'مرحباً بك 👋',
                    style: NeuroTypography.h1,
                  ),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFAEE4FF),
                      Color(0xFF10265A),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: NeuroColors.primaryLight.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 26,
                  color: Color(0xFFAEE4FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.xl),
          _buildStatsRow(
            context,
            patientCount: patientCount,
            alertCount: alertCount,
            stableCount: stableCount,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    required int patientCount,
    required int alertCount,
    required int stableCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF12192A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(NeuroRadius.lg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem(context, 'مرضى', '$patientCount',
              NeuroColors.textPrimary),
          _buildStatDivider(context),
          _buildStatItem(context, 'إنذارات', '$alertCount',
              NeuroColors.critical),
          _buildStatDivider(context),
          _buildStatItem(context, 'مستقر', '$stableCount', NeuroColors.low),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: NeuroTypography.displayLarge?.copyWith(
              fontSize: 26,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: NeuroTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  // ─── Quick Actions ───────────────────────────────────────────────
  Widget _buildQuickActions(
    BuildContext context,
    AsyncValue<List<dynamic>> patientsAsync,
  ) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.sos,
          label: 'SOS',
          color: const Color(0xFFE53935),
          onTap: () {
            final patients = patientsAsync.valueOrNull ?? [];
            if (patients.isNotEmpty) {
              final id = patients.first['id'] ?? patients.first['patient_id'];
              context.push('/patients/$id/sos');
            } else {
              context.push('/alerts');
            }
          },
        ),
        _QuickAction(
          icon: Icons.map_outlined,
          label: 'الخريطة',
          color: const Color(0xFF1A73E8),
          onTap: () => context.push('/map'),
        ),
        _QuickAction(
          icon: Icons.description_outlined,
          label: 'التقارير',
          color: const Color(0xFF8E24AA),
          onTap: () => context.push('/reports'),
        ),
        _QuickAction(
          icon: Icons.devices_other,
          label: 'الأجهزة',
          color: const Color(0xFF00ACC1),
          onTap: () => context.push('/devices'),
        ),
      ],
    );
  }

  // ─── Device Status Card ──────────────────────────────────────────
  Widget _buildDeviceStatusCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> devicesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E2A47), Color(0xFF0A1B33)],
        ),
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: const [NeuroShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('حالة الأجهزة', style: NeuroTypography.h3),
              TextButton(
                onPressed: () => context.push('/devices'),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.sm),
          devicesAsync.when(
            loading: () => const AppLoading(),
            error: (err, _) => Row(
              children: [
                const Icon(Icons.cloud_off, color: NeuroColors.error),
                const SizedBox(width: NeuroSpacing.sm),
                Expanded(
                  child: Text(
                    'تعذر الاتصال بالخادم لعرض حالة الأجهزة',
                    style: NeuroTypography.caption,
                  ),
                ),
              ],
            ),
            data: (devices) {
              final online = devices.where((d) {
                final s = (d['status'] as String?)?.toLowerCase();
                return s == 'online' || s == 'active' || s == 'connected';
              }).toList();
              final connected = online.isNotEmpty ? online.first : null;
              final total = devices.length;

              if (total == 0) {
                return Column(
                  children: [
                    const AppEmptyState(
                      icon: Icons.sensors_off,
                      title: 'لا توجد أجهزة متصلة',
                      message: 'قم بتوصيل جهاز مراقبة لبدء متابعة القياسات',
                    ),
                    const SizedBox(height: NeuroSpacing.sm),
                    AppButton(
                      label: 'توصيل جهاز',
                      icon: Icons.link,
                      onPressed: () => context.push('/devices/pair'),
                    ),
                  ],
                );
              }

              final battery = (connected?['battery_level'] as num?)?.toDouble();
              final signal =
                  (connected?['signal_strength'] as num?)?.toDouble();
              final deviceName = connected?['device_name'] ??
                  connected?['serial_number'] ??
                  'جهاز';
              final lastSeen = connected?['last_seen'] as String?;

              return Column(
                children: [
                  Row(
                    children: [
                      _DeviceStatusPill(
                        icon: Icons.circle,
                        color: connected != null
                            ? const Color(0xFF1ACB58)
                            : NeuroColors.critical,
                        label: connected != null ? 'متصلة' : 'غير متصلة',
                      ),
                      const SizedBox(width: NeuroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connected != null ? '$deviceName' : '—',
                              style: NeuroTypography.bodyMedium?.copyWith(
                                color: NeuroColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              lastSeen != null
                                  ? 'آخر تحديث: $lastSeen'
                                  : 'آخر تحديث: —',
                              style: NeuroTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NeuroSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _DeviceMiniMetric(
                          icon: Icons.battery_full,
                          value: battery != null
                              ? '${battery.toStringAsFixed(0)}%'
                              : '—',
                          label: 'البطارية',
                        ),
                      ),
                      Expanded(
                        child: _DeviceMiniMetric(
                          icon: Icons.network_cell,
                          value: signal != null
                              ? '${signal.toStringAsFixed(0)}%'
                              : '—',
                          label: 'قوة الاتصال',
                        ),
                      ),
                      Expanded(
                        child: _DeviceMiniMetric(
                          icon: Icons.sensors,
                          value: '$total',
                          label: 'إجمالي الأجهزة',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: NeuroTypography.h2),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('عرض الكل'),
        ),
      ],
    );
  }

  // ─── Patient Cards ────────────────────────────────────────────────
  List<Widget> _buildPatientCards(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> patientsAsync,
  ) {
    return patientsAsync.when(
      loading: () => [
        const AppLoading(),
      ],
      error: (err, _) => [
        AppErrorState(
          title: 'تعذر تحميل المرضى',
          message: '$err',
          onRetry: () => ref.invalidate(patientsProvider),
        ),
      ],
      data: (patients) {
        if (patients.isEmpty) {
          return [
            AppEmptyState(
              icon: Icons.person_add_alt_1,
              title: 'لا يوجد مرضى مسجلين',
              message: 'ابدأ بإضافة أول مريض',
              actionLabel: 'إضافة مريض',
              onAction: () => context.push('/patients/create'),
            ),
          ];
        }
        return patients.take(4).map((patient) {
          return Padding(
            padding: const EdgeInsets.only(bottom: NeuroSpacing.md),
            child: _PatientCard(patient: patient),
          );
        }).toList();
      },
    );
  }

  // ─── Alert Tiles ──────────────────────────────────────────────────
  List<Widget> _buildAlertTiles(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> alertsAsync,
  ) {
    return alertsAsync.when(
      loading: () => [
        const AppLoading(),
      ],
      error: (err, _) => [
        AppErrorState(
          title: 'تعذر تحميل الإنذارات',
          message: '$err',
          onRetry: () => ref.invalidate(recentAlertsProvider),
        ),
      ],
      data: (alerts) {
        if (alerts.isEmpty) {
          return [
            const AppEmptyState(
              icon: Icons.notifications_none,
              title: 'لا توجد إنذارات حالية',
              message: 'سيتم إشعارك عند وجود إنذارات جديدة',
            ),
          ];
        }
        return alerts.take(3).map((alert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: NeuroSpacing.md),
            child: _AlertTile(alert: alert),
          );
        }).toList();
      },
    );
  }
}

// ─── Quick Action Button ───────────────────────────────────────────
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Device Status Pill ────────────────────────────────────────────
class _DeviceStatusPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _DeviceStatusPill({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeuroSpacing.sm,
        vertical: NeuroSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(NeuroRadius.badge),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: NeuroTypography.badge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Device Mini Metric ────────────────────────────────────────────
class _DeviceMiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _DeviceMiniMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(NeuroSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(NeuroRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: NeuroColors.primaryLight, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: NeuroTypography.h3?.copyWith(
              color: NeuroColors.textPrimary,
            ),
          ),
          Text(label, style: NeuroTypography.caption),
        ],
      ),
    );
  }
}

// ─── Patient Card (Home) ─────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final dynamic patient;

  const _PatientCard({required this.patient});

  Color get _riskColor {
    final level = (patient['risk_level'] as String?)?.toLowerCase();
    final score = (patient['risk_score'] as num?)?.toDouble() ?? 0;
    switch (level) {
      case 'critical':
        return NeuroColors.critical;
      case 'high':
        return NeuroColors.high;
      case 'medium':
        return NeuroColors.medium;
      case 'low':
        return NeuroColors.low;
      default:
        return score >= 0.7
            ? NeuroColors.critical
            : score >= 0.4
                ? NeuroColors.high
                : NeuroColors.low;
    }
  }

  String get _riskLabel {
    final level = (patient['risk_level'] as String?)?.toLowerCase();
    switch (level) {
      case 'critical':
        return 'حرج';
      case 'high':
        return 'مرتفع';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return 'منخفض';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = patient['full_name'] ?? 'مريض';
    final mrn = patient['mrn'] ?? '—';
    final isActive = patient['is_active'] != false;
    final riskScore = ((patient['risk_score'] as num?)?.toDouble() ?? 0)
        .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NeuroColors.cardGradTop, NeuroColors.cardGradBottom],
        ),
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        boxShadow: const [NeuroShadows.card],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: NeuroColors.primary.withValues(alpha: 0.3),
                    child: Text(
                      name.toString().isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: NeuroColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? const Color(0xFF1ACB58)
                            : NeuroColors.critical,
                        border: Border.all(
                          color: NeuroColors.bgCard,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: NeuroSpacing.md),
              // Name + MRN
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: NeuroTypography.h3?.copyWith(
                        color: NeuroColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MRN: $mrn',
                      style: NeuroTypography.caption,
                    ),
                  ],
                ),
              ),
              // Risk badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: NeuroSpacing.sm,
                  vertical: NeuroSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(NeuroRadius.badge),
                  border: Border.all(color: _riskColor),
                ),
                child: Text(
                  _riskLabel,
                  style: NeuroTypography.badge.copyWith(color: _riskColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.md),
          // Risk score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: riskScore,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(_riskColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Tile (Home) ───────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final dynamic alert;

  const _AlertTile({required this.alert});

  Color get _severityColor {
    final severity = (alert['severity'] as String?)?.toLowerCase();
    switch (severity) {
      case 'critical':
        return NeuroColors.criticalBright;
      case 'high':
        return NeuroColors.high;
      case 'medium':
        return NeuroColors.medium;
      default:
        return NeuroColors.low;
    }
  }

  IconData get _severityIcon {
    final severity = (alert['severity'] as String?)?.toLowerCase();
    switch (severity) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'high':
      case 'medium':
        return Icons.warning_rounded;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = (alert['severity'] as String?)?.toLowerCase() ?? 'low';
    final isCritical = severity == 'critical';

    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.md),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.md),
        border: Border(
          left: BorderSide(
            color: _severityColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(NeuroRadius.sm),
            ),
            child: Icon(
              _severityIcon,
              color: _severityColor,
              size: 22,
            ),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['alert_type'] ?? 'إنذار',
                  style: NeuroTypography.h3?.copyWith(
                    color: isCritical
                        ? NeuroColors.criticalBright
                        : NeuroColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  alert['message'] ?? '',
                  style: NeuroTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: NeuroSpacing.sm),
          Text(
            _formatTime(alert['created_at']),
            style: NeuroTypography.caption,
          ),
        ],
      ),
    );
  }
}
