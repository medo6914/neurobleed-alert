import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'providers/patients_providers.dart';

class VitalsHistoryScreen extends ConsumerWidget {
  final String patientId;
  const VitalsHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(patientVitalsProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Vitals History'), centerTitle: true),
      body: vitalsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (vitals) {
          if (vitals.isEmpty) {
            return AppEmptyState(
              icon: Icons.monitor_heart,
              title: 'No Vitals',
              message: 'No vital signs recorded yet',
            );
          }

          final latest = vitals.first;
          return ListView(
            padding: EdgeInsets.all(NeuroSpacing.md),
            children: [
              AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_heart, color: NeuroColors.primary),
                          SizedBox(width: NeuroSpacing.sm),
                          Text('Latest Vitals', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(_formatDateTime(latest.timestamp), style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                        ],
                      ),
                      SizedBox(height: NeuroSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _vitalWidget('HR', '${latest.heartRate?.toStringAsFixed(0) ?? "-"}', '/min', _hrColor(latest.heartRate)),
                          _vitalWidget('SpO₂', '${latest.oxygenSaturation?.toStringAsFixed(0) ?? "-"}', '%', _spo2Color(latest.oxygenSaturation)),
                          _vitalWidget('BP', latest.systolicBP != null ? '${latest.systolicBP!.toInt()}' : '-', 'mmHg', NeuroColors.primary),
                          _vitalWidget('Temp', '${latest.temperature?.toStringAsFixed(1) ?? "-"}', '°C', NeuroColors.primary),
                        ],
                      ),
                      SizedBox(height: NeuroSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _vitalWidget('RR', '${latest.respiratoryRate?.toStringAsFixed(0) ?? "-"}', '/min', NeuroColors.primary),
                          _vitalWidget('ICP', '${latest.icp?.toStringAsFixed(0) ?? "-"}', 'mmHg', NeuroColors.critical),
                          _vitalWidget('CPP', '${latest.cpp?.toStringAsFixed(0) ?? "-"}', 'mmHg', NeuroColors.warning),
                          _vitalWidget('Glucose', '${latest.glucose?.toStringAsFixed(0) ?? "-"}', 'mg/dL', NeuroColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: NeuroSpacing.md),

              Text('History', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: NeuroSpacing.sm),
              ...vitals.map((v) => Padding(
                padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                child: AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDateTime(v.timestamp), style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                              SizedBox(height: 2),
                              Text('HR ${v.heartRate?.toStringAsFixed(0) ?? "-"} | SpO₂ ${v.oxygenSaturation?.toStringAsFixed(0) ?? "-"}%'),
                              Text('BP ${v.systolicBP?.toInt() ?? "-"}/${v.diastolicBP?.toInt() ?? "-"} | Temp ${v.temperature?.toStringAsFixed(1) ?? "-"}°C',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (v.riskScore != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (v.riskScore! >= 0.7 ? Colors.red : v.riskScore! >= 0.4 ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(NeuroRadius.sm),
                            ),
                            child: Text('${(v.riskScore! * 100).toInt()}%', style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: v.riskScore! >= 0.7 ? Colors.red : v.riskScore! >= 0.4 ? Colors.orange : Colors.green,
                            )),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _vitalWidget(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Color _hrColor(double? hr) {
    if (hr == null) return NeuroColors.primary;
    if (hr < 60 || hr > 100) return NeuroColors.critical;
    return NeuroColors.stable;
  }

  Color _spo2Color(double? spo2) {
    if (spo2 == null) return NeuroColors.primary;
    if (spo2 < 90) return NeuroColors.critical;
    if (spo2 < 95) return NeuroColors.warning;
    return NeuroColors.stable;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
