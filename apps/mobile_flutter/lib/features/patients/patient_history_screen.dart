import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';
import 'providers/patients_providers.dart';

class PatientHistoryScreen extends ConsumerWidget {
  final String patientId;
  const PatientHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(patientHistoryProvider(patientId));
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.t('patientHistory')),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: localizations.t('error'),
          message: e.toString(),
        ),
        data: (data) => ListView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          children: [
            Text(localizations.t('admissions'), style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary,
            )),
            SizedBox(height: NeuroSpacing.sm),
            if (data.admissions.isEmpty)
              AppCard(child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.md),
                child: Text(localizations.t('noData')),
              ))
            else ...data.admissions.map((a) => _HistoryCard(
              title: '${a.admissionType ?? "N/A"} - ${a.admissionDate.toLocal().toString().substring(0, 10)}',
              subtitle: '${a.ward ?? "N/A"} / Bed ${a.bedNumber ?? "N/A"}',
              trailing: a.status.name,
              statusColor: a.status == AdmissionStatus.active ? NeuroColors.stable : NeuroColors.textSecondary,
            )),
            SizedBox(height: NeuroSpacing.lg),

            Text(localizations.t('notes'), style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary,
            )),
            SizedBox(height: NeuroSpacing.sm),
            if (data.notes.isEmpty)
              AppCard(child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.md),
                child: Text(localizations.t('noData')),
              ))
            else ...data.notes.map((n) => _HistoryCard(
              title: n.title,
              subtitle: n.createdAt.toLocal().toString().substring(0, 16),
              trailing: n.type.name,
              statusColor: NeuroColors.info,
            )),
            SizedBox(height: NeuroSpacing.lg),

            Text(localizations.t('vitals'), style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary,
            )),
            SizedBox(height: NeuroSpacing.sm),
            if (data.vitals.isEmpty)
              AppCard(child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.md),
                child: Text(localizations.t('noData')),
              ))
            else ...data.vitals.map((v) => _HistoryCard(
              title: 'HR: ${v.heartRate?.toStringAsFixed(0) ?? "-"} | BP: ${v.systolicBP?.toInt() ?? "-"}/${v.diastolicBP?.toInt() ?? "-"}',
              subtitle: v.timestamp.toLocal().toString().substring(0, 16),
              trailing: 'SpO2: ${v.oxygenSaturation?.toStringAsFixed(0) ?? "-"}%',
              statusColor: NeuroColors.primary,
            )),
            SizedBox(height: NeuroSpacing.lg),

            Text(localizations.t('alerts'), style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary,
            )),
            SizedBox(height: NeuroSpacing.sm),
            if (data.alerts.isEmpty)
              AppCard(child: Padding(
                padding: EdgeInsets.all(NeuroSpacing.md),
                child: Text(localizations.t('noData')),
              ))
            else ...data.alerts.map((a) => _HistoryCard(
              title: a.title,
              subtitle: a.createdAt.toLocal().toString().substring(0, 16),
              trailing: a.level,
              statusColor: a.level == 'critical' ? NeuroColors.critical : NeuroColors.warning,
            )),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color statusColor;

  const _HistoryCard({
    required this.title, required this.subtitle,
    required this.trailing, required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
      child: AppCard(
        child: ListTile(
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: Chip(
            label: Text(trailing, style: const TextStyle(fontSize: 10)),
            backgroundColor: statusColor.withValues(alpha: 0.1),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}
