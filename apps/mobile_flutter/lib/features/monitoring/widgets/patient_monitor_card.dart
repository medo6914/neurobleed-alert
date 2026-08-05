import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'vital_sign_gauge.dart';

class PatientMonitorCard extends StatelessWidget {
  final String patientId;
  final String patientName;
  final Map<String, dynamic>? vitals;
  final bool hasAlert;
  final VoidCallback onTap;

  const PatientMonitorCard({
    super.key,
    required this.patientId,
    required this.patientName,
    this.vitals,
    this.hasAlert = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NeuroRadius.lg),
        border:
            hasAlert ? Border.all(color: NeuroColors.error, width: 2) : null,
      ),
      child: AppCard(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      patientName,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasAlert)
                    const Icon(Icons.warning_rounded,
                        color: NeuroColors.error, size: 20),
                ],
              ),
              SizedBox(height: NeuroSpacing.md),
              if (vitals != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    VitalSignGauge(
                      label: 'HR',
                      value: (vitals!['heart_rate'] as num?)?.toDouble(),
                      unit: 'bpm',
                      normalRange: Range(60, 100),
                      icon: Icons.favorite,
                    ),
                    VitalSignGauge(
                      label: 'SpO2',
                      value: (vitals!['spo2'] as num?)?.toDouble(),
                      unit: '%',
                      normalRange: Range(95, 100),
                      icon: Icons.air,
                    ),
                    VitalSignGauge(
                      label: 'rSO2',
                      value: (vitals!['rso2'] as num?)?.toDouble(),
                      unit: '%',
                      normalRange: Range(60, 80),
                      icon: Icons.monitor_heart,
                    ),
                  ],
                ),
                SizedBox(height: NeuroSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRiskBadge(vitals!['risk_level'] as String?),
                    _buildTrendBadge(vitals!['trend'] as String?),
                  ],
                ),
              ] else
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Text(
                      'Waiting for data\u2026',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String? riskLevel) {
    final color = switch (riskLevel) {
      'critical' => NeuroColors.error,
      'high' => NeuroColors.high,
      'medium' => NeuroColors.medium,
      'low' => NeuroColors.success,
      _ => NeuroColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        riskLevel?.toUpperCase() ?? '--',
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTrendBadge(String? trend) {
    final icon = switch (trend) {
      'worsening' => Icons.trending_up,
      'improving' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    final color = switch (trend) {
      'worsening' => NeuroColors.error,
      'improving' => NeuroColors.success,
      _ => NeuroColors.textSecondary,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          trend?.toUpperCase() ?? '--',
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
