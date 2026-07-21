import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_providers.dart';
import '../widgets/ai_widgets.dart';

class RiskAssessmentScreen extends ConsumerStatefulWidget {
  final String patientId;

  const RiskAssessmentScreen({super.key, required this.patientId});

  @override
  ConsumerState<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends ConsumerState<RiskAssessmentScreen> {
  final _hrCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _rso2Ctrl = TextEditingController();
  final _sbpCtrl = TextEditingController();
  final _dbpCtrl = TextEditingController();
  final _gcsCtrl = TextEditingController();
  double _signalQuality = 0.9;
  double _motionArtifact = 0.1;

  @override
  void dispose() {
    _hrCtrl.dispose();
    _spo2Ctrl.dispose();
    _rso2Ctrl.dispose();
    _sbpCtrl.dispose();
    _dbpCtrl.dispose();
    _gcsCtrl.dispose();
    super.dispose();
  }

  void _assess() {
    ref.read(riskAssessmentProvider.notifier).assessRisk(
      patientId: widget.patientId,
      heartRate: double.tryParse(_hrCtrl.text),
      spo2: double.tryParse(_spo2Ctrl.text),
      rso2: double.tryParse(_rso2Ctrl.text),
      systolicBp: double.tryParse(_sbpCtrl.text),
      diastolicBp: double.tryParse(_dbpCtrl.text),
      gcs: double.tryParse(_gcsCtrl.text),
      signalQuality: _signalQuality,
      motionArtifact: _motionArtifact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(riskAssessmentProvider);
    final result = state.result;

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Assessment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Input Vitals',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildTextField(_hrCtrl, 'Heart Rate (bpm)', Icons.favorite),
                    _buildTextField(_spo2Ctrl, 'SpO2 (%)', Icons.air),
                    _buildTextField(_rso2Ctrl, 'rSO2 (%)', Icons.psychology),
                    _buildTextField(_sbpCtrl, 'Systolic BP (mmHg)', Icons.water_drop),
                    _buildTextField(_dbpCtrl, 'Diastolic BP (mmHg)', Icons.water_drop),
                    _buildTextField(_gcsCtrl, 'GCS Score', Icons.healing),
                    const SizedBox(height: 16),
                    Text('Signal Quality',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Slider(
                      value: _signalQuality,
                      onChanged: (v) => setState(() => _signalQuality = v),
                      min: 0,
                      max: 1,
                      divisions: 20,
                    ),
                    Text('Motion Artifact',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Slider(
                      value: _motionArtifact,
                      onChanged: (v) => setState(() => _motionArtifact = v),
                      min: 0,
                      max: 1,
                      divisions: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: state.isAssessing ? null : _assess,
                icon: state.isAssessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.assessment),
                label: Text(state.isAssessing ? 'Assessing...' : 'Assess Risk'),
              ),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            if (result != null) ...[
              const SizedBox(height: 24),
              Card(
                color: result.riskScore >= 0.6
                    ? Colors.red.withValues(alpha: 0.05)
                    : result.riskScore >= 0.3
                        ? Colors.amber.withValues(alpha: 0.05)
                        : Colors.green.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      RiskScoreIndicator(
                        score: result.riskScore,
                        level: result.riskLevel,
                        confidence: result.confidence,
                      ),
                      const SizedBox(height: 16),
                      if (result.trend != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              result.trend == 'worsening'
                                  ? Icons.trending_up
                                  : result.trend == 'improving'
                                      ? Icons.trending_down
                                      : Icons.trending_flat,
                              color: result.trend == 'worsening'
                                  ? Colors.red
                                  : result.trend == 'improving'
                                      ? Colors.green
                                      : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Trend: ${result.trend!.toUpperCase()}',
                              style: TextStyle(
                                color: result.trend == 'worsening'
                                    ? Colors.red
                                    : result.trend == 'improving'
                                        ? Colors.green
                                        : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      if (result.contributingFactors.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Contributing Factors',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: result.contributingFactors
                              .map((f) => ContributingFactorsChip(factor: f))
                              .toList(),
                        ),
                      ],
                      if (result.rulesTriggered.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Rules Triggered',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )),
                        const SizedBox(height: 8),
                        ...result.rulesTriggered.map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.rule, size: 16, color: Colors.orange.shade700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(r, style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Model: ${result.modelVersion ?? "N/A"}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      Text(
                        'Inference: ${result.inferenceTimeMs.toStringAsFixed(1)}ms',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
