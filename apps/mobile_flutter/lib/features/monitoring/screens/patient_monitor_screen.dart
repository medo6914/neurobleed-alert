import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../providers/monitoring_providers.dart';
import '../widgets/vital_sign_gauge.dart';

class PatientMonitorScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientMonitorScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientMonitorScreen> createState() => _PatientMonitorScreenState();
}

class _PatientMonitorScreenState extends ConsumerState<PatientMonitorScreen> {
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    final client = ref.read(webSocketClientProvider);
    client.subscribe(widget.patientId);
    _subscribed = true;
  }

  void _unsubscribe() {
    if (_subscribed) {
      final client = ref.read(webSocketClientProvider);
      client.unsubscribe(widget.patientId);
      _subscribed = false;
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vitals = ref.watch(patientLiveVitalsProvider(widget.patientId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Monitor'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: NeuroColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Patient: ${widget.patientId.substring(0, 8)}',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (vitals != null) ...[
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          VitalSignGauge(
                            label: 'Heart Rate',
                            value: (vitals['heart_rate'] as num?)?.toDouble(),
                            unit: 'bpm',
                            normalRange: Range(60, 100),
                            icon: Icons.favorite,
                          ),
                          VitalSignGauge(
                            label: 'SpO2',
                            value: (vitals['spo2'] as num?)?.toDouble(),
                            unit: '%',
                            normalRange: Range(95, 100),
                            icon: Icons.air,
                          ),
                          VitalSignGauge(
                            label: 'rSO2',
                            value: (vitals['rso2'] as num?)?.toDouble(),
                            unit: '%',
                            normalRange: Range(60, 80),
                            icon: Icons.monitor_heart,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          VitalSignGauge(
                            label: 'Signal',
                            value: (vitals['signal_quality'] as num?)?.toDouble(),
                            unit: '',
                            normalRange: Range(0.5, 1.0),
                            icon: Icons.signal_cellular_alt,
                          ),
                          VitalSignGauge(
                            label: 'Motion',
                            value: (vitals['motion_artifact'] as num?)?.toDouble(),
                            unit: '',
                            normalRange: Range(0, 0.3),
                            icon: Icons.run_circle,
                          ),
                          VitalSignGauge(
                            label: 'IR',
                            value: (vitals['ir_value'] as num?)?.toDouble(),
                            unit: '',
                            normalRange: Range(0, 4096),
                            icon: Icons.wb_sunny,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Risk Assessment', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip('Risk Score',
                              '${((vitals['risk_score'] as num?)?.toDouble() ?? 0) * 100}%'),
                          const SizedBox(width: 12),
                          _buildInfoChip('Level',
                              (vitals['risk_level'] as String? ?? '--').toUpperCase()),
                          const SizedBox(width: 12),
                          _buildInfoChip('Trend',
                              (vitals['trend'] as String? ?? '--').toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Subscribing to patient monitor\u2026',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NeuroColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: NeuroColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: NeuroColors.primary)),
        ],
      ),
    );
  }
}
