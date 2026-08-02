import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';

final _patientRisksProvider = FutureProvider.family<List<RiskRecord>, String>((ref, patientId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/v1/patients/$patientId/risks');
  return (response.data['data'] as List)
      .map((e) => RiskRecord.fromJson(e as Map<String, dynamic>))
      .toList();
});

class RiskHistoryScreen extends ConsumerWidget {
  final String patientId;
  const RiskHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risksAsync = ref.watch(_patientRisksProvider(patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Risk History'), centerTitle: true),
      body: risksAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (risks) {
          if (risks.isEmpty) {
            return AppEmptyState(
              icon: Icons.assessment,
              title: 'No Risk Assessments',
              message: 'No risk assessments recorded yet',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: risks.length,
            itemBuilder: (context, index) {
              final risk = risks[index];
              final scoreColor = risk.score < 0.3
                  ? Colors.green
                  : risk.score < 0.6
                      ? Colors.orange
                      : risk.score < 0.8
                          ? NeuroColors.warning
                          : NeuroColors.critical;

              return Padding(
                padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                child: AppCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scoreColor.withValues(alpha: 0.2),
                      child: Text('${(risk.score * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scoreColor)),
                    ),
                    title: Text(risk.riskType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level: ${risk.level}'),
                        Text(risk.timestamp.toLocal().toString().substring(0, 16), style: TextStyle(fontSize: 12, color: NeuroColors.textSecondary)),
                      ],
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _levelColor(risk.level).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(NeuroRadius.sm),
                      ),
                      child: Text(risk.level.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _levelColor(risk.level))),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'critical': return NeuroColors.critical;
      case 'high': return Colors.red;
      case 'moderate': return NeuroColors.warning;
      default: return Colors.green;
    }
  }
}
