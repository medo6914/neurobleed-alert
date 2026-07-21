import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'providers/patients_providers.dart';

class MedicalTimelineScreen extends ConsumerWidget {
  final String patientId;
  const MedicalTimelineScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(patientTimelineProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Timeline'), centerTitle: true),
      body: timelineAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (entries) {
          if (entries.isEmpty) {
            return AppEmptyState(
              icon: Icons.timeline,
              title: 'No Timeline Events',
              message: 'No medical timeline events recorded',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _TimelineEntryWidget(entry: entry, isLast: index == entries.length - 1);
            },
          );
        },
      ),
    );
  }
}

class _TimelineEntryWidget extends StatelessWidget {
  final MedicalTimelineEntry entry;
  final bool isLast;

  const _TimelineEntryWidget({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _eventColor(entry.eventType);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 2),
                  ),
                  child: Icon(_eventIcon(entry.eventType), size: 16, color: iconColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: NeuroSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.lg),
              child: AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(
                            entry.timestamp.toLocal().toString().substring(0, 16),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      if (entry.description.isNotEmpty) ...[
                        SizedBox(height: NeuroSpacing.xs),
                        Text(entry.description, style: theme.textTheme.bodyMedium),
                      ],
                      if (entry.createdByName != null) ...[
                        SizedBox(height: NeuroSpacing.xs),
                        Text('by ${entry.createdByName}', style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _eventColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.admission: return NeuroColors.primary;
      case TimelineEventType.discharge: return NeuroColors.stable;
      case TimelineEventType.surgery: return NeuroColors.critical;
      case TimelineEventType.alertTriggered: return NeuroColors.warning;
      case TimelineEventType.diagnosis: return NeuroColors.info;
      case TimelineEventType.medicationChange: return NeuroColors.primary;
      case TimelineEventType.vitalsAbnormal: return NeuroColors.critical;
      default: return Colors.grey;
    }
  }

  IconData _eventIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.admission: return Icons.local_hospital;
      case TimelineEventType.discharge: return Icons.exit_to_app;
      case TimelineEventType.surgery: return Icons.biotech;
      case TimelineEventType.alertTriggered: return Icons.warning;
      case TimelineEventType.diagnosis: return Icons.medical_services;
      case TimelineEventType.medicationChange: return Icons.medication;
      case TimelineEventType.vitalsAbnormal: return Icons.monitor_heart;
      default: return Icons.circle;
    }
  }
}
