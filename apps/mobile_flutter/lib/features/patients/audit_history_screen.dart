import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'providers/patients_providers.dart';

class AuditHistoryScreen extends ConsumerWidget {
  final String patientId;
  const AuditHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(patientAuditProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log'), centerTitle: true),
      body: auditAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (records) {
          if (records.isEmpty) {
            return AppEmptyState(
              icon: Icons.history,
              title: 'No Audit Records',
              message: 'No audit records found',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final actionColor = record.action == 'create'
                  ? NeuroColors.success
                  : record.action == 'update'
                      ? NeuroColors.primary
                      : record.action == 'delete'
                          ? NeuroColors.critical
                          : record.action == 'view_sensitive'
                              ? NeuroColors.warning
                              : NeuroColors.textSecondary;

              return Padding(
                padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                child: AppCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: actionColor.withValues(alpha: 0.1),
                      child: Icon(_actionIcon(record.action),
                          color: actionColor, size: 20),
                    ),
                    title: Text(
                        record.action.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: actionColor)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${record.resourceType}${record.resourceId != null ? ' #${record.resourceId!.substring(0, 8)}' : ''}'),
                        if (record.userName != null)
                          Text(
                              'by ${record.userName} (${record.userRole ?? "N/A"})'),
                        Text(
                            record.timestamp
                                .toLocal()
                                .toString()
                                .substring(0, 16),
                            style: TextStyle(
                                fontSize: 12,
                                color: NeuroColors.textSecondary)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: record.changes != null &&
                            record.changes!.isNotEmpty
                        ? Icon(Icons.change_circle, color: NeuroColors.warning)
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'view_sensitive':
        return Icons.visibility;
      case 'export':
        return Icons.file_download;
      default:
        return Icons.info;
    }
  }
}
