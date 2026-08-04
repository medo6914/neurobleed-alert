import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final analyticsOverviewProvider = FutureProvider<AnalyticsOverview>((ref) async {
  final api = ref.watch(analyticsApiProvider);
  final response = await api.getOverview();
  return AnalyticsOverview.fromJson(response.data as Map<String, dynamic>);
});

final activityFeedProvider = FutureProvider<List<ActivityFeedItem>>((ref) async {
  final api = ref.watch(analyticsApiProvider);
  final response = await api.getActivityFeed(limit: 20);
  return (response.data as List).map((e) => ActivityFeedItem.fromJson(e as Map<String, dynamic>)).toList();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final feedAsync = ref.watch(activityFeedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(analyticsOverviewProvider);
              ref.invalidate(activityFeedProvider);
            },
          ),
        ],
      ),
      body: overviewAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: 'Error',
          message: e.toString(),
          onRetry: () => ref.invalidate(analyticsOverviewProvider),
        ),
        data: (overview) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(NeuroSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Overview', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: NeuroSpacing.md),
                _SummaryGrid(overview: overview),
                SizedBox(height: NeuroSpacing.lg),
                Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: NeuroSpacing.sm),
                _QuickActions(theme: theme),
                SizedBox(height: NeuroSpacing.lg),
                Text('Recent Activity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: NeuroSpacing.sm),
                feedAsync.when(
                  loading: () => const AppLoading(),
                  error: (e, _) => Text('Failed to load activity'),
                  data: (items) => _ActivityFeed(items: items, theme: theme),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final AnalyticsOverview overview;

  const _SummaryGrid({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.people, label: 'Patients', value: '${overview.activePatients}/${overview.totalPatients}',
              color: NeuroColors.primaryLight, subtitle: 'active/total',
            )),
            SizedBox(width: NeuroSpacing.sm),
            Expanded(child: _MetricCard(
              icon: Icons.devices, label: 'Devices', value: '${overview.onlineDevices}/${overview.totalDevices}',
              color: NeuroColors.low, subtitle: 'online/total',
            )),
          ],
        ),
        SizedBox(height: NeuroSpacing.sm),
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.warning, label: 'Alerts', value: '${overview.criticalAlerts}/${overview.totalAlerts}',
              color: NeuroColors.criticalBright, subtitle: 'critical/total',
            )),
            SizedBox(width: NeuroSpacing.sm),
            Expanded(child: _MetricCard(
              icon: Icons.local_hospital, label: 'Occupancy', value: '${overview.bedOccupancyRate.toStringAsFixed(0)}%',
              color: NeuroColors.medium, subtitle: 'bed occupancy',
            )),
          ],
        ),
        SizedBox(height: NeuroSpacing.sm),
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.business, label: 'Hospitals', value: '${overview.totalHospitals}',
              color: NeuroColors.info,
            )),
            SizedBox(width: NeuroSpacing.sm),
            Expanded(child: _MetricCard(
              icon: Icons.person, label: 'Users', value: '${overview.totalUsers}',
              color: NeuroColors.info,
            )),
          ],
        ),
        SizedBox(height: NeuroSpacing.sm),
        Row(
          children: [
            Expanded(child: _MetricCard(
              icon: Icons.description, label: 'Reports', value: '${overview.reportsGenerated}',
              color: NeuroColors.textSecondary,
            )),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _MetricCard({
    required this.icon, required this.label, required this.value,
    required this.color, this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(NeuroSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: NeuroSpacing.sm),
            Text(value,
                style: NeuroTypography.displayLarge?.copyWith(
                  fontSize: 30,
                  color: NeuroColors.textPrimary,
                )),
            SizedBox(height: 2),
            Text(label, style: NeuroTypography.caption),
            if (subtitle != null)
              Text(subtitle!, style: NeuroTypography.caption),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ThemeData theme;
  const _QuickActions({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ActionCard(
              icon: Icons.people, label: 'Patient Analytics',
              color: NeuroColors.primaryLight,
              onTap: () => context.push('/analytics/patients'),
            )),
            SizedBox(width: NeuroSpacing.sm),
            Expanded(child: _ActionCard(
              icon: Icons.devices, label: 'Device Fleet',
              color: NeuroColors.low,
              onTap: () => context.push('/analytics/devices'),
            )),
          ],
        ),
        SizedBox(height: NeuroSpacing.sm),
        Row(
          children: [
            Expanded(child: _ActionCard(
              icon: Icons.warning, label: 'Alert Analytics',
              color: NeuroColors.criticalBright,
              onTap: () => context.push('/analytics/alerts'),
            )),
            SizedBox(width: NeuroSpacing.sm),
            Expanded(child: _ActionCard(
              icon: Icons.business, label: 'Hospital Overview',
              color: NeuroColors.medium,
              onTap: () => context.push('/analytics/hospitals'),
            )),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon, required this.label, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(NeuroSpacing.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(NeuroSpacing.sm),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(NeuroRadius.md)),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: NeuroSpacing.sm),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  final List<ActivityFeedItem> items;
  final ThemeData theme;

  const _ActivityFeed({required this.items, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppEmptyState(icon: Icons.history, title: 'No Activity', message: 'No recent activity recorded.');
    }
    return Column(
      children: items.take(10).map((item) => Padding(
        padding: EdgeInsets.only(bottom: NeuroSpacing.xs),
        child: AppCard(
          child: Padding(
            padding: EdgeInsets.all(NeuroSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.eventType.contains('error') ? NeuroColors.critical : NeuroColors.low,
                  ),
                ),
                SizedBox(width: NeuroSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description.length > 60 ? '${item.description.substring(0, 60)}...' : item.description,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      if (item.userName != null)
                        Text(item.userName!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text(_formatTime(item.timestamp), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
