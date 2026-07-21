import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import '../providers/device_providers.dart';

class DeviceHistoryScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceHistoryScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(deviceHistoryProvider(deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(deviceHistoryProvider(deviceId)),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: 'Error Loading History',
          message: e.toString(),
          onRetry: () => ref.invalidate(deviceHistoryProvider(deviceId)),
        ),
        data: (history) {
          if (history.isEmpty) {
            return AppEmptyState(
              icon: Icons.history,
              title: 'No History',
              message: 'No events recorded for this device.',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final event = history[index] as Map<String, dynamic>;
              return _EventTile(event: event);
            },
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = event['event_type'] as String? ?? 'unknown';
    final timestamp = event['timestamp'] as String? ?? '';
    final details = event['details'] as String? ?? event['message'] as String? ?? '';
    final metadata = event['metadata'] as Map<String, dynamic>?;

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'heartbeat':
        icon = Icons.favorite;
        iconColor = const Color(0xFF4CAF50);
      case 'status_change':
        icon = Icons.swap_horiz;
        iconColor = const Color(0xFF2196F3);
      case 'fw_update':
      case 'firmware_update':
        icon = Icons.system_update;
        iconColor = const Color(0xFFF57C00);
      case 'assignment':
        icon = Icons.link;
        iconColor = const Color(0xFF9C27B0);
      case 'unassignment':
        icon = Icons.link_off;
        iconColor = const Color(0xFFFF5722);
      case 'error':
      case 'alert':
        icon = Icons.error;
        iconColor = const Color(0xFFE53935);
      case 'pairing':
        icon = Icons.bluetooth;
        iconColor = const Color(0xFF2196F3);
      default:
        icon = Icons.circle;
        iconColor = theme.colorScheme.onSurfaceVariant;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(NeuroSpacing.xs),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: AppCard(
              child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type.replaceAll('_', ' ').toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          timestamp.isNotEmpty ? timestamp.substring(0, 16) : '',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    if (details.isNotEmpty) ...[
                      SizedBox(height: NeuroSpacing.xs),
                      Text(details, style: theme.textTheme.bodySmall),
                    ],
                    if (metadata != null && metadata.isNotEmpty) ...[
                      SizedBox(height: NeuroSpacing.xs),
                      ...metadata.entries.map((e) => Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Text(
                              '${e.key}: ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get historyLength => 0; // Will be overridden via context
}
