import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final hospitalOverviewProvider = FutureProvider<HospitalOverview>((ref) async {
  final api = ref.watch(analyticsApiProvider);
  final response = await api.getHospitalOverview();
  return HospitalOverview.fromJson(response.data as Map<String, dynamic>);
});

final systemHealthProvider = FutureProvider<SystemHealth>((ref) async {
  final api = ref.watch(analyticsApiProvider);
  final response = await api.getSystemHealth();
  return SystemHealth.fromJson(response.data as Map<String, dynamic>);
});

class HospitalAdminScreen extends ConsumerWidget {
  const HospitalAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalAsync = ref.watch(hospitalOverviewProvider);
    final healthAsync = ref.watch(systemHealthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital & System Admin')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(NeuroSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Health', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: NeuroSpacing.sm),
            healthAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppErrorState(title: 'Error', message: e.toString(), onRetry: () => ref.invalidate(systemHealthProvider)),
              data: (health) => Column(
                children: [
                  _HealthRow(icon: Icons.speed, label: 'Avg Response', value: '${health.avgResponseTimeMs.toStringAsFixed(0)} ms', color: health.avgResponseTimeMs > 500 ? const Color(0xFFEA4335) : const Color(0xFF34A853)),
                  SizedBox(height: NeuroSpacing.xs),
                  _HealthRow(icon: Icons.error_outline, label: 'Error Rate (24h)', value: '${(health.errorRate24h * 100).toStringAsFixed(1)}%', color: health.errorRate24h > 0.05 ? const Color(0xFFEA4335) : const Color(0xFF34A853)),
                  SizedBox(height: NeuroSpacing.xs),
                  _HealthRow(icon: Icons.cloud_download, label: 'Requests (24h)', value: '${_formatNumber(health.totalRequests24h)}', color: const Color(0xFF1A73E8)),
                  SizedBox(height: NeuroSpacing.xs),
                  _HealthRow(icon: Icons.wifi, label: 'WebSockets', value: '${health.activeWebSockets}', color: const Color(0xFF8E24AA)),
                  SizedBox(height: NeuroSpacing.xs),
                  _HealthRow(icon: Icons.storage, label: 'DB Connections', value: '${health.databaseConnections}', color: const Color(0xFF00ACC1)),
                  SizedBox(height: NeuroSpacing.xs),
                  _HealthRow(icon: Icons.cached, label: 'Cache Hit Rate', value: '${(health.cacheHitRate * 100).toStringAsFixed(0)}%', color: health.cacheHitRate > 0.8 ? const Color(0xFF34A853) : const Color(0xFFFBBC04)),
                  SizedBox(height: NeuroSpacing.xs),
                  _HealthRow(icon: Icons.timer, label: 'Uptime', value: '${health.uptimeHours.toStringAsFixed(0)}h', color: const Color(0xFF34A853)),
                  if (health.recentErrors.isNotEmpty) ...[
                    SizedBox(height: NeuroSpacing.lg),
                    Text('Recent Errors', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: NeuroSpacing.sm),
                    ...health.recentErrors.map((e) => Padding(
                      padding: EdgeInsets.only(bottom: NeuroSpacing.xs),
                      child: AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(NeuroSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e['message'] ?? 'Unknown error'}', style: theme.textTheme.bodySmall),
                              if (e['timestamp'] != null) Text('${e['timestamp']}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
            SizedBox(height: NeuroSpacing.lg),
            Text('Hospitals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: NeuroSpacing.sm),
            hospitalAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppErrorState(title: 'Error', message: e.toString(), onRetry: () => ref.invalidate(hospitalOverviewProvider)),
              data: (overview) => Column(
                children: [
                  Row(children: [
                    Expanded(child: _HospitalMetricCard(label: 'Total', value: '${overview.totalHospitals}', icon: Icons.business, color: const Color(0xFF1A73E8))),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _HospitalMetricCard(label: 'Total Beds', value: '${overview.totalBeds}', icon: Icons.hotel, color: const Color(0xFF34A853))),
                  ]),
                  SizedBox(height: NeuroSpacing.sm),
                  Row(children: [
                    Expanded(child: _HospitalMetricCard(label: 'Occupied', value: '${overview.occupiedBeds}', icon: Icons.person, color: const Color(0xFFFBBC04))),
                    SizedBox(width: NeuroSpacing.sm),
                    Expanded(child: _HospitalMetricCard(
                      label: 'Occupancy Rate',
                      value: overview.totalBeds > 0 ? '${((overview.occupiedBeds / overview.totalBeds) * 100).toStringAsFixed(0)}%' : '0%',
                      icon: Icons.analytics, color: const Color(0xFF8E24AA),
                    )),
                  ]),
                  SizedBox(height: NeuroSpacing.lg),
                  Text('Hospital List', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: NeuroSpacing.sm),
                  ...overview.hospitals.map((h) => Padding(
                    padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                    child: AppCard(
                      child: Padding(
                        padding: EdgeInsets.all(NeuroSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                            SizedBox(height: NeuroSpacing.sm),
                            Row(children: [
                              _MiniStat(label: 'Patients', value: '${h.patientCount}'),
                              SizedBox(width: NeuroSpacing.md),
                              _MiniStat(label: 'Devices', value: '${h.deviceCount}'),
                              SizedBox(width: NeuroSpacing.md),
                              _MiniStat(label: 'Alerts', value: '${h.activeAlerts}'),
                            ]),
                            SizedBox(height: NeuroSpacing.xs),
                            Row(children: [
                              _MiniStat(label: 'Bed Cap', value: '${h.bedCapacity}'),
                              SizedBox(width: NeuroSpacing.md),
                              _MiniStat(label: 'Occupancy', value: '${(h.bedOccupancy * 100).toStringAsFixed(0)}%'),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _HealthRow extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _HealthRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: NeuroSpacing.sm, horizontal: NeuroSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: NeuroSpacing.sm),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _HospitalMetricCard extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _HospitalMetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label; final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
