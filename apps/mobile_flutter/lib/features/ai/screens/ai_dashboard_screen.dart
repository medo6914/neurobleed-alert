import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../providers/ai_providers.dart';

class AIDashboardScreen extends ConsumerStatefulWidget {
  const AIDashboardScreen({super.key});

  @override
  ConsumerState<AIDashboardScreen> createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends ConsumerState<AIDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardStatsProvider.notifier).fetchStats());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardStatsProvider);
    final stats = state.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Platform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardStatsProvider.notifier).fetchStats(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: AppLoading())
          : state.error != null
              ? AppErrorState(
                  title: 'Error Loading Dashboard',
                  message: state.error!,
                  onRetry: () => ref.read(dashboardStatsProvider.notifier).fetchStats(),
                )
              : _DashboardContent(
                  stats: stats!,
                  onRefresh: () => ref.read(dashboardStatsProvider.notifier).fetchStats(),
                ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardStatsDto stats;
  final VoidCallback onRefresh;

  const _DashboardContent({required this.stats, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatsGrid(stats: stats),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Risk Score Distribution',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _RiskDistributionChart(distribution: stats.riskDistribution),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alerts by Severity',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _AlertSeverityChart(alertsBySeverity: stats.alertsBySeverity),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ModelStatusCard(stats: stats),
          const SizedBox(height: 16),
          if (stats.recentActivity.isNotEmpty) ...[
            Text('Recent Activity',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...stats.recentActivity.take(5).map((activity) => _ActivityItem(activity: activity)),
          ],
          const SizedBox(height: 16),
          _ActionCards(),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStatsDto stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 400 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: [
            _StatTile(label: 'Assessments', value: '${stats.totalAssessments}', icon: Icons.assessment, color: NeuroColors.info),
            _StatTile(label: 'Alerts', value: '${stats.totalAlerts}', icon: Icons.warning, color: NeuroColors.critical),
            _StatTile(label: 'Active Patients', value: '${stats.activePatients}', icon: Icons.people, color: NeuroColors.success),
            _StatTile(label: 'Active Devices', value: '${stats.activeDevices}', icon: Icons.devices, color: NeuroColors.low),
            _StatTile(label: 'Avg Risk', value: '${(stats.avgRiskScore * 100).round()}%', icon: Icons.speed, color: NeuroColors.high),
            _StatTile(label: 'Docs Indexed', value: '${stats.ragDocumentCount}', icon: Icons.menu_book, color: NeuroColors.temperature),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: NeuroColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RiskDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const _RiskDistributionChart({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const Text('No data yet');

    const colors = {
      'low': NeuroColors.success,
      'medium': NeuroColors.medium,
      'high': NeuroColors.high,
      'critical': NeuroColors.critical,
    };

    return Column(
      children: distribution.entries.map((entry) {
        final ratio = entry.value / total;
        final color = colors[entry.key] ?? NeuroColors.textSecondary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${entry.key.toUpperCase()}  (${entry.value})',
                      style: TextStyle(fontSize: 12, color: color)),
                  Text('${(ratio * 100).round()}%',
                      style: TextStyle(fontSize: 12, color: color)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AlertSeverityChart extends StatelessWidget {
  final Map<String, int> alertsBySeverity;

  const _AlertSeverityChart({required this.alertsBySeverity});

  @override
  Widget build(BuildContext context) {
    if (alertsBySeverity.isEmpty) return const Text('No alerts yet');

    const colors = {
      'low': NeuroColors.success,
      'medium': NeuroColors.medium,
      'high': NeuroColors.high,
      'critical': NeuroColors.critical,
    };

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: alertsBySeverity.entries.map((entry) {
        final color = colors[entry.key] ?? NeuroColors.textSecondary;
        return Chip(
          avatar: Icon(Icons.warning, color: color, size: 16),
          label: Text('${entry.key}: ${entry.value}'),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }
}

class _ModelStatusCard extends StatelessWidget {
  final DashboardStatsDto stats;

  const _ModelStatusCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: NeuroColors.success.withValues(alpha: stats.modelTrained ? 0.05 : 0.02),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              stats.modelTrained ? Icons.check_circle : Icons.info_outline,
              color: stats.modelTrained ? NeuroColors.success : NeuroColors.high,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Service Status',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    'Model: ${stats.modelVersion}  |  ${stats.ragIndexLoaded ? "RAG loaded" : "RAG not loaded"}',
                    style: TextStyle(fontSize: 12, color: NeuroColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stats.modelTrained ? NeuroColors.success : NeuroColors.high,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stats.modelTrained ? 'Online' : 'Training',
                style: const TextStyle(color: NeuroColors.textPrimary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final score = (activity['risk_score'] as num?)?.toDouble() ?? 0.0;
    final level = activity['risk_level'] as String? ?? 'unknown';
    final color = score >= 0.8 ? NeuroColors.critical : score >= 0.6 ? NeuroColors.high : score >= 0.3 ? NeuroColors.medium : NeuroColors.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.circle, color: color, size: 12),
        title: Text('Risk Score: ${(score * 100).round()}%',
            style: const TextStyle(fontSize: 13)),
        subtitle: Text(activity['created_at']?.toString().substring(0, 19) ?? '',
            style: const TextStyle(fontSize: 11)),
        trailing: Chip(
          label: Text(level.toUpperCase(), style: const TextStyle(fontSize: 10)),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _ActionCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.assessment, color: NeuroColors.info),
            title: const Text('Risk Assessment'),
            subtitle: const Text('Real-time risk scoring from vitals'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ai'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history, color: NeuroColors.low),
            title: const Text('Risk History'),
            subtitle: const Text('View past risk assessments'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/ai'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book, color: NeuroColors.temperature),
            title: const Text('Knowledge Base'),
            subtitle: const Text('Search medical knowledge'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/knowledge'),
          ),
        ),
      ],
    );
  }
}
