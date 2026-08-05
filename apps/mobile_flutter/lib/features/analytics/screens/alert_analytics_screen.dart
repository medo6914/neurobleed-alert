import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final alertAnalyticsProvider = FutureProvider<AlertAnalytics>((ref) async {
  final api = ref.watch(analyticsApiProvider);
  final response = await api.getAlertAnalytics();
  return AlertAnalytics.fromJson(response.data as Map<String, dynamic>);
});

class AlertAnalyticsScreen extends ConsumerWidget {
  const AlertAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertAnalyticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Analytics')),
      body: async.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: 'Error',
          message: e.toString(),
          onRetry: () => ref.invalidate(alertAnalyticsProvider),
        ),
        data: (data) => SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Severity Breakdown',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                    child: _AlertSeverityCard(
                        label: 'Critical',
                        value: data.critical,
                        color: NeuroColors.critical)),
                SizedBox(width: 4),
                Expanded(
                    child: _AlertSeverityCard(
                        label: 'High',
                        value: data.high,
                        color: NeuroColors.high)),
                SizedBox(width: 4),
                Expanded(
                    child: _AlertSeverityCard(
                        label: 'Medium',
                        value: data.medium,
                        color: NeuroColors.medium)),
              ]),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                    child: _AlertSeverityCard(
                        label: 'Low', value: data.low, color: NeuroColors.low)),
                SizedBox(width: NeuroSpacing.sm),
                Expanded(
                    child: _AlertSeverityCard(
                        label: 'Unacknowledged',
                        value: data.unacknowledged,
                        color: NeuroColors.chartBlue)),
              ]),
              SizedBox(height: NeuroSpacing.lg),
              Text('Response Time',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: NeuroSpacing.sm),
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.timer,
                          color: data.averageResponseTimeMinutes > 10
                              ? NeuroColors.critical
                              : NeuroColors.low),
                      SizedBox(width: NeuroSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Average Response Time',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          Text(
                              '${data.averageResponseTimeMinutes.toStringAsFixed(1)} minutes',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (data.bySeverity.isNotEmpty) ...[
                SizedBox(height: NeuroSpacing.lg),
                Text('By Severity',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: NeuroSpacing.sm),
                ...data.bySeverity.map((s) => Padding(
                      padding: EdgeInsets.only(bottom: NeuroSpacing.xs),
                      child: AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(NeuroSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text('${s['severity'] ?? 'Unknown'}',
                                      style: theme.textTheme.bodyMedium)),
                              Text('${s['count'] ?? 0}',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
              if (data.byType.isNotEmpty) ...[
                SizedBox(height: NeuroSpacing.lg),
                Text('By Type',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: NeuroSpacing.sm),
                ...data.byType.map((t) => Padding(
                      padding: EdgeInsets.only(bottom: NeuroSpacing.xs),
                      child: AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(NeuroSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text('${t['type'] ?? 'Unknown'}',
                                      style: theme.textTheme.bodyMedium)),
                              Text('${t['count'] ?? 0}',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertSeverityCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AlertSeverityCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: NeuroSpacing.sm, horizontal: NeuroSpacing.xs),
        child: Column(
          children: [
            Text('$value',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
