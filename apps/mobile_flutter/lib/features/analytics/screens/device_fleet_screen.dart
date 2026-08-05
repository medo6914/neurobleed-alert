import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final deviceAnalyticsProvider = FutureProvider<DeviceAnalytics>((ref) async {
  final api = ref.watch(analyticsApiProvider);
  final response = await api.getDeviceAnalytics();
  return DeviceAnalytics.fromJson(response.data as Map<String, dynamic>);
});

class DeviceFleetScreen extends ConsumerWidget {
  const DeviceFleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deviceAnalyticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Device Fleet Overview')),
      body: async.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: 'Error',
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceAnalyticsProvider),
        ),
        data: (data) => SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status Distribution',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                    child: _StatusBadge(
                        label: 'Online',
                        value: data.online,
                        color: NeuroColors.low)),
                SizedBox(width: 4),
                Expanded(
                    child: _StatusBadge(
                        label: 'Offline',
                        value: data.offline,
                        color: NeuroColors.textSecondary)),
                SizedBox(width: 4),
                Expanded(
                    child: _StatusBadge(
                        label: 'Error',
                        value: data.error,
                        color: NeuroColors.critical)),
              ]),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                    child: _StatusBadge(
                        label: 'Maintenance',
                        value: data.maintenance,
                        color: NeuroColors.medium)),
                SizedBox(width: 4),
                Expanded(
                    child: _StatusBadge(
                        label: 'Sleeping',
                        value: data.sleeping,
                        color: NeuroColors.chartBlue)),
                SizedBox(width: 4),
                Expanded(
                    child: _StatusBadge(
                        label: 'Updating',
                        value: data.updating,
                        color: NeuroColors.temperature)),
              ]),
              SizedBox(height: NeuroSpacing.lg),
              Text('Battery',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: NeuroSpacing.sm),
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.battery_charging_full,
                          color: data.averageBattery > 50
                              ? NeuroColors.low
                              : NeuroColors.critical),
                      SizedBox(width: NeuroSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Average Battery: ${data.averageBattery.toStringAsFixed(0)}%',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text('${data.lowBatteryCount} devices below 20%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              if (data.byStatus.isNotEmpty) ...[
                SizedBox(height: NeuroSpacing.lg),
                Text('By Status',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: NeuroSpacing.sm),
                ...data.byStatus.map((s) => Padding(
                      padding: EdgeInsets.only(bottom: NeuroSpacing.xs),
                      child: AppCard(
                        child: Padding(
                          padding: EdgeInsets.all(NeuroSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text('${s['status'] ?? 'Unknown'}',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatusBadge(
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
