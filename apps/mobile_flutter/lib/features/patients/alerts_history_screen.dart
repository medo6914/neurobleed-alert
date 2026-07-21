import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'providers/patients_providers.dart';

class AlertsHistoryScreen extends ConsumerStatefulWidget {
  final String patientId;
  const AlertsHistoryScreen({super.key, required this.patientId});

  @override
  ConsumerState<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends ConsumerState<AlertsHistoryScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(patientAlertsProvider(widget.patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts History'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _statusFilter = v),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              const PopupMenuItem(value: 'active', child: Text('Active')),
              const PopupMenuItem(value: 'acknowledged', child: Text('Acknowledged')),
              const PopupMenuItem(value: 'resolved', child: Text('Resolved')),
            ],
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (alerts) {
          var filtered = alerts;
          if (_statusFilter != null) {
            filtered = alerts.where((AlertRecord a) => a.status.name == _statusFilter).toList();
          }

          if (filtered.isEmpty) {
            return AppEmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Alerts',
              message: _statusFilter != null ? 'No $_statusFilter alerts' : 'No alerts recorded',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final alert = filtered[index];
              final severityColor = alert.level == 'critical'
                  ? NeuroColors.critical
                  : alert.level == 'warning'
                      ? NeuroColors.warning
                      : NeuroColors.info;

              return Padding(
                padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                child: AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 12, color: severityColor),
                            SizedBox(width: NeuroSpacing.sm),
                            Expanded(
                              child: Text(alert.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            Chip(
                              label: Text(alert.status.name, style: const TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: alert.status == AlertStatus.active
                                  ? NeuroColors.critical
                                  : alert.status == AlertStatus.acknowledged
                                      ? NeuroColors.warning
                                      : Colors.green,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        SizedBox(height: NeuroSpacing.xs),
                        Text(alert.description, style: Theme.of(context).textTheme.bodyMedium),
                        SizedBox(height: NeuroSpacing.sm),
                        Row(
                          children: [
                            Text(alert.createdAt.toLocal().toString().substring(0, 16), style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )),
                            if (alert.riskScore != null) ...[
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: severityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(NeuroRadius.sm),
                                ),
                                child: Text('Risk: ${(alert.riskScore! * 100).toInt()}%', style: TextStyle(fontSize: 10, color: severityColor)),
                              ),
                            ],
                          ],
                        ),
                        if (alert.status == AlertStatus.active) ...[
                          SizedBox(height: NeuroSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppButton(
                                label: 'Acknowledge',
                                icon: Icons.check,
                                variant: ButtonVariant.secondary,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
