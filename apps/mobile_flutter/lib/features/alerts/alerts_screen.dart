import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';

import 'package:core/core.dart';

final alertsProvider = FutureProvider<List>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/alerts/', queryParameters: {'acknowledged': false});
  final data = response.data;
  if (data is Map && data['items'] is List) return data['items'] as List;
  if (data is List) return data;
  return [];
});

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String _severityFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإنذارات'),
        backgroundColor: NeuroColors.navBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(alertsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(alertsProvider),
        child: alertsAsync.when(
          loading: () => const Center(child: AppLoading()),
          error: (err, _) => AppErrorState(
            title: 'تعذر تحميل الإنذارات',
            message: '$err',
            onRetry: () => ref.invalidate(alertsProvider),
          ),
          data: (alerts) {
            final filtered = _severityFilter == 'all'
                ? alerts
                : alerts
                    .where((a) =>
                        (a['severity'] as String?)?.toLowerCase() ==
                        _severityFilter)
                    .toList();

            if (filtered.isEmpty) {
              return const AppEmptyState(
                icon: Icons.notifications_none,
                title: 'لا توجد إنذارات',
                message: 'جميع الأنظمة تعمل بشكل طبيعي',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(NeuroSpacing.lg),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: NeuroSpacing.md),
                  child: _AlertCard(
                    alert: filtered[index],
                    onAcknowledge: () => _acknowledgeAlert(
                      filtered[index]['id'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _acknowledgeAlert(dynamic alertId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/v1/alerts/${alertId}/acknowledge', data: {});
      ref.invalidate(alertsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تأكيد الإنذار')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تأكيد الإنذار: $e')),
        );
      }
    }
  }

  void _showFilterMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NeuroColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final filters = [
          ('all', 'الكل'),
          ('critical', 'حرج'),
          ('high', 'مرتفع'),
          ('medium', 'متوسط'),
          ('low', 'منخفض'),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: NeuroSpacing.lg),
              Text('تصفية الإنذارات', style: NeuroTypography.h2),
              const SizedBox(height: NeuroSpacing.sm),
              ...filters.map((f) {
                return ListTile(
                  title: Text(
                    f.$2,
                    style: NeuroTypography.bodyMedium?.copyWith(
                      color: _severityFilter == f.$1
                          ? NeuroColors.primaryLight
                          : NeuroColors.textBody,
                    ),
                  ),
                  trailing: _severityFilter == f.$1
                      ? const Icon(
                          Icons.check_circle,
                          color: NeuroColors.primaryLight,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    setState(() => _severityFilter = f.$1);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: NeuroSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final dynamic alert;
  final VoidCallback onAcknowledge;

  const _AlertCard({required this.alert, required this.onAcknowledge});

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
        return Icons.info_outline_rounded;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = (alert['severity'] as String?)?.toLowerCase() ?? 'low';
    final isCritical = severity == 'critical';

    return Container(
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.md),
        border: Border(
          left: BorderSide(color: _severityColor, width: 5),
        ),
        boxShadow: const [NeuroShadows.card],
      ),
      child: Padding(
        padding: const EdgeInsets.all(NeuroSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_severityIcon, color: _severityColor, size: 22),
                const SizedBox(width: NeuroSpacing.sm),
                Expanded(
                  child: Text(
                    alert['alert_type'] ?? 'إنذار',
                    style: NeuroTypography.h3?.copyWith(
                      color: isCritical
                          ? NeuroColors.criticalBright
                          : NeuroColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatTime(alert['created_at']),
                  style: NeuroTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: NeuroSpacing.sm),
            Text(
              alert['message'] ?? '',
              style: NeuroTypography.bodyMedium,
            ),
            if ((alert['risk_score'] as num?) != null) ...[
              const SizedBox(height: NeuroSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: _severityColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'درجة الخطر: ${(alert['risk_score'] as num).toStringAsFixed(2)}',
                    style: NeuroTypography.caption.copyWith(
                      color: _severityColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: NeuroSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAcknowledge,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _severityColor,
                      side: BorderSide(
                          color: _severityColor.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                    ),
                    child: const Text('تأكيد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
