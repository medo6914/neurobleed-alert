import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_providers.dart';

class RiskHistoryScreen extends ConsumerStatefulWidget {
  final String patientId;

  const RiskHistoryScreen({super.key, required this.patientId});

  @override
  ConsumerState<RiskHistoryScreen> createState() => _RiskHistoryScreenState();
}

class _RiskHistoryScreenState extends ConsumerState<RiskHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(riskAssessmentProvider.notifier).loadHistory(widget.patientId);
    });
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) return Colors.red;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.3) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riskAssessmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk History')),
      body: state.isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : state.history.isEmpty
              ? const Center(child: Text('No risk assessments found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.history.length,
                  itemBuilder: (context, index) {
                    final item = state.history[index];
                    final color = _scoreColor(item.riskScore);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(
                            '${(item.riskScore * 100).round()}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          item.riskLabel,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.contributingFactors.isNotEmpty)
                              Text(
                                item.contributingFactors.join(', '),
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (item.trend != null)
                              Row(
                                children: [
                                  Icon(
                                    item.trend == 'worsening'
                                        ? Icons.trending_up
                                        : item.trend == 'improving'
                                            ? Icons.trending_down
                                            : Icons.trending_flat,
                                    size: 14,
                                    color: item.trend == 'worsening'
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.trend!,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (item.rulesTriggered.isNotEmpty)
                              Text(
                                '${item.rulesTriggered.length} rules',
                                style: const TextStyle(fontSize: 10, color: Colors.orange),
                              ),
                            Text(
                              '${item.confidence.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
