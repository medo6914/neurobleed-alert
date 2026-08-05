import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_card.dart';

class VitalsData {
  final double heartRate;
  final double oxygenSaturation;
  final double systolicBP;
  final double diastolicBP;
  final double temperature;
  final double respiratoryRate;
  final double icp;
  final double cpp;

  const VitalsData({
    required this.heartRate,
    required this.oxygenSaturation,
    required this.systolicBP,
    required this.diastolicBP,
    required this.temperature,
    required this.respiratoryRate,
    required this.icp,
    required this.cpp,
  });
}

class PatientVitalsCard extends StatelessWidget {
  final String patientName;
  final VitalsData vitals;
  final String? lastUpdated;

  const PatientVitalsCard({
    super.key,
    required this.patientName,
    required this.vitals,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NeuroTypography.textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(patientName, style: theme.titleLarge),
              if (lastUpdated != null)
                Text(lastUpdated!,
                    style: theme.bodySmall?.copyWith(
                      color: NeuroColors.textSecondary,
                    )),
            ],
          ),
          const SizedBox(height: NeuroSpacing.lg),
          _buildVitalGrid(theme),
        ],
      ),
    );
  }

  Widget _buildVitalGrid(TextTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: NeuroSpacing.md,
          crossAxisSpacing: NeuroSpacing.md,
          childAspectRatio: 1.8,
          children: [
            _buildVitalTile(
              'HR',
              '${vitals.heartRate.toInt()}',
              'bpm',
              NeuroColors.heartRate,
              theme,
            ),
            _buildVitalTile(
              'SpO2',
              '${vitals.oxygenSaturation.toInt()}',
              '%',
              NeuroColors.oxygenSaturation,
              theme,
            ),
            _buildVitalTile(
              'BP',
              '${vitals.systolicBP.toInt()}/${vitals.diastolicBP.toInt()}',
              'mmHg',
              NeuroColors.bloodPressureSystolic,
              theme,
            ),
            _buildVitalTile(
              'Temp',
              vitals.temperature.toStringAsFixed(1),
              '°C',
              NeuroColors.temperature,
              theme,
            ),
            _buildVitalTile(
              'RR',
              '${vitals.respiratoryRate.toInt()}',
              '/min',
              NeuroColors.respiratoryRate,
              theme,
            ),
            _buildVitalTile(
              'ICP',
              '${vitals.icp.toInt()}',
              'mmHg',
              NeuroColors.icp,
              theme,
            ),
            _buildVitalTile(
              'CPP',
              '${vitals.cpp.toInt()}',
              'mmHg',
              NeuroColors.cpp,
              theme,
            ),
            _buildVitalTile(
              'O2',
              '${vitals.oxygenSaturation.toInt()}',
              '%',
              NeuroColors.oxygenSaturation,
              theme,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVitalTile(
    String label,
    String value,
    String unit,
    Color color,
    TextTheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(NeuroRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: theme.labelSmall?.copyWith(color: color)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: theme.titleMedium?.copyWith(color: color)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(unit,
                    style: theme.labelSmall?.copyWith(
                      color: color.withAlpha(180),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
