import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

final notificationSubscriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/subscriptions/');
  final data = response.data;
  if (data is List) return data.cast<Map<String, dynamic>>();
  if (data is Map && data['items'] is List) return (data['items'] as List).cast<Map<String, dynamic>>();
  return [];
});

final alertFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/alerts/', queryParameters: {'per_page': 15});
  final data = response.data;
  if (data is List) return data.cast<Map<String, dynamic>>();
  if (data is Map && data['items'] is List) return (data['items'] as List).cast<Map<String, dynamic>>();
  return [];
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<int> _dismissedIds = {};

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(notificationSubscriptionsProvider);
    final alertsAsync = ref.watch(alertFeedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(notificationSubscriptionsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationSubscriptionsProvider),
        child: subscriptionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Unable to load notifications', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('$err', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(notificationSubscriptionsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (subscriptions) {
            final activeSubs = subscriptions.where((s) => s['status'] == 'active' || s['status'] == 'trialing').toList();
            final filtered = subscriptions.where((s) => !_dismissedIds.contains(subscriptions.indexOf(s))).toList();

            if (filtered.isEmpty && activeSubs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('All caught up', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('No notifications at this time', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('أحداث النظام',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                ),
                ..._buildAlertFeed(alertsAsync, theme),
                const SizedBox(height: 16),
                if (activeSubs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Active Subscriptions', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                  ),
                  ...activeSubs.map((sub) => _buildSubscriptionCard(sub, theme)),
                  const SizedBox(height: 16),
                ],
                if (filtered.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('History', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  ...filtered.map((item) {
                    final index = subscriptions.indexOf(item);
                    final tier = item['tier'] as String? ?? 'Standard';
                    final status = item['status'] as String? ?? 'unknown';
                    final startDate = item['start_date'] as String? ?? '';
                    final endDate = item['end_date'] as String? ?? '';

                    return Dismissible(
                      key: ValueKey('sub_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: NeuroColors.critical,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline, color: NeuroColors.textPrimary),
                      ),
                      onDismissed: (_) {
                        setState(() => _dismissedIds.add(index));
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: status == 'active'
                                ? NeuroColors.success.withValues(alpha: 0.2)
                                : NeuroColors.textSecondary.withValues(alpha: 0.2),
                            child: Icon(
                              status == 'active' ? Icons.notifications_active : Icons.notifications_off,
                              color: status == 'active' ? NeuroColors.success : NeuroColors.textSecondary,
                            ),
                          ),
                          title: Text('$tier Plan', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (status == 'active' ? NeuroColors.success : NeuroColors.textSecondary).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(status, style: TextStyle(fontSize: 12, color: status == 'active' ? NeuroColors.success : NeuroColors.textSecondary)),
                                ),
                              ]),
                              if (startDate.isNotEmpty) Text(startDate, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAlertFeed(
      AsyncValue<List<Map<String, dynamic>>> alertsAsync, ThemeData theme) {
    if (alertsAsync.isLoading) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (alertsAsync.hasError) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: theme.colorScheme.error, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تعذر تحميل الأحداث: ${alertsAsync.error}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    final alerts = alertsAsync.value ?? [];
    if (alerts.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NeuroColors.textSecondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_none, color: NeuroColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'لا توجد أحداث حالية — سيتم إشعارك عند حدوث إنذارات',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return alerts.map((alert) => _AlertEventTile(alert: alert)).toList();
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub, ThemeData theme) {
    final tier = sub['tier'] as String? ?? 'Standard';
    final startDate = sub['start_date'] as String? ?? '';
    final endDate = sub['end_date'] as String? ?? '';
    final autoRenew = sub['auto_renew'] as bool? ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (startDate.isNotEmpty) Text('Started: $startDate', style: theme.textTheme.bodySmall),
                  if (endDate.isNotEmpty) Text('Ends: $endDate', style: theme.textTheme.bodySmall),
                  Row(children: [
                    Icon(Icons.check_circle, size: 14, color: NeuroColors.success),
                    const SizedBox(width: 4),
                    Text(autoRenew ? 'Auto-renew' : 'Manual renew', style: const TextStyle(fontSize: 11)),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: NeuroColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Active', style: TextStyle(color: NeuroColors.success, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertEventTile extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertEventTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = (alert['alert_type'] as String? ?? 'general')
        .replaceAll('_', ' ');
    final severity = (alert['severity'] as String? ?? 'low').toLowerCase();
    final message = alert['message'] as String? ?? '';
    final createdAt = alert['created_at'] as String? ?? '';
    final acknowledged = alert['acknowledged'] == true;

    final (icon, color) = _mapType(severity, type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type.toUpperCase(),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (acknowledged)
                      const Text('✓',
                          style: TextStyle(color: NeuroColors.success, fontSize: 12)),
                  ],
                ),
                if (message.isNotEmpty)
                  Text(message,
                      style: theme.textTheme.bodySmall, maxLines: 2),
                if (createdAt.isNotEmpty)
                  Text(_formatTime(createdAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: NeuroColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _mapType(String severity, String type) {
    if (severity == 'critical' || severity == 'high') {
      return (Icons.warning_amber_rounded, NeuroColors.critical);
    }
    switch (type) {
      case 'icp_elevated':
      case 'bleed risk':
        return (Icons.bloodtype_outlined, NeuroColors.critical);
      case 'desaturation':
        return (Icons.air, NeuroColors.high);
      case 'bradycardia':
      case 'tachycardia':
      case 'arrhythmia':
        return (Icons.monitor_heart_outlined, NeuroColors.temperature);
      case 'hypotension':
      case 'hypertension':
        return (Icons.speed, NeuroColors.high);
      case 'system':
        return (Icons.settings_suggest_outlined, NeuroColors.textSecondary);
      default:
        return (Icons.notifications_outlined, NeuroColors.info);
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
