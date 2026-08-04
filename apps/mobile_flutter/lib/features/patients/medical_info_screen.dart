import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'providers/patients_providers.dart';

class MedicalInfoScreen extends ConsumerWidget {
  final String patientId;
  const MedicalInfoScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Center(child: Text(t.t('medicalInfo'))), centerTitle: true),
      body: patientAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (patient) => SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (patient.primaryDiagnosis != null) ...[
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.medical_services, color: NeuroColors.critical, size: 32),
                      SizedBox(width: NeuroSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Primary Diagnosis', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            Text(patient.primaryDiagnosis!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: NeuroSpacing.md),
              ],
              _section(context, 'Diagnoses', Icons.check_circle, NeuroColors.stable, patient.diagnoses),
              _section(context, 'Allergies', Icons.warning_amber, NeuroColors.high, patient.allergies),
              _section(context, 'Medications', Icons.medication, NeuroColors.primary, patient.medications),
              _section(context, 'Comorbidities', Icons.heart_broken, NeuroColors.warning, patient.comorbidities),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon, Color color, List<String> items) {
    return Padding(
      padding: EdgeInsets.only(bottom: NeuroSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: NeuroSpacing.xs),
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: NeuroSpacing.sm),
          AppCard(
            child: items.isEmpty
                ? Padding(padding: EdgeInsets.all(NeuroSpacing.md), child: Text('No $title recorded'))
                : Column(
                    children: items.map((item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: NeuroSpacing.xs),
                      child: Row(
                        children: [
                          Icon(Icons.fiber_manual_record, size: 8, color: color),
                          SizedBox(width: NeuroSpacing.sm),
                          Text(item),
                        ],
                      ),
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
