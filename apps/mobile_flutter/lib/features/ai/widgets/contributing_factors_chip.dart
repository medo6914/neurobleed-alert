import 'package:flutter/material.dart';

final _factorLabels = <String, String>{
  'abnormal_heart_rate': 'Abnormal HR',
  'hypoxia': 'Hypoxia',
  'cerebral_desaturation': 'Cerebral Desat',
  'neurological_deficit': 'Neuro Deficit',
  'hemodynamic_instability': 'Hemodynamic',
};

class ContributingFactorsChip extends StatelessWidget {
  final String factor;

  const ContributingFactorsChip({super.key, required this.factor});

  IconData get _icon {
    switch (factor) {
      case 'abnormal_heart_rate':
        return Icons.favorite;
      case 'hypoxia':
        return Icons.air;
      case 'cerebral_desaturation':
        return Icons.psychology;
      case 'neurological_deficit':
        return Icons.hearing;
      case 'hemodynamic_instability':
        return Icons.water_drop;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_icon, size: 16, color: Colors.red.shade400),
      label: Text(
        _factorLabels[factor] ?? factor,
        style: const TextStyle(fontSize: 11),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Colors.red.withValues(alpha: 0.05),
      side: BorderSide.none,
    );
  }
}
