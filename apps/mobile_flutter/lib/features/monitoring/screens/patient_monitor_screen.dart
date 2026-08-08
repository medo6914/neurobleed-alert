import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'package:shared/entities/vitals_record.dart';
import '../providers/monitoring_providers.dart';
import '../widgets/vital_sign_gauge.dart';
import '../../patients/providers/patient_vitals_provider.dart';

class PatientMonitorScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientMonitorScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientMonitorScreen> createState() =>
      _PatientMonitorScreenState();
}

class _PatientMonitorScreenState extends ConsumerState<PatientMonitorScreen> {
  bool _subscribed = false;
  final List<FlSpot> _heartRateHistory = [];
  static const _maxPoints = 40;

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
    final latestVitalsAsync = ref.watch(latestVitalsProvider(widget.patientId));
    final theme = Theme.of(context);

    ref.listen<Map<String, dynamic>?>(
      patientLiveVitalsProvider(widget.patientId),
      (prev, next) {
        final hr = next?['heart_rate'];
        if (hr is num && next!['timestamp'] is String) {
          final time = DateTime.parse(next['timestamp'] as String)
              .toLocal()
              .millisecondsSinceEpoch;
          setState(() {
            _heartRateHistory.add(FlSpot(time.toDouble(), hr.toDouble()));
            if (_heartRateHistory.length > _maxPoints) {
              _heartRateHistory.removeAt(0);
            }
          });
        }
      },
    );

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
                Expanded(
                  child: Text(
                    'Patient: ${widget.patientId.substring(0, 8)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  _formatLastUpdate(vitals, latestVitalsAsync.valueOrNull),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: NeuroColors.textSecondary),
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
                            value:
                                (vitals['signal_quality'] as num?)?.toDouble(),
                            unit: '',
                            normalRange: Range(0.5, 1.0),
                            icon: Icons.signal_cellular_alt,
                          ),
                          VitalSignGauge(
                            label: 'Motion',
                            value:
                                (vitals['motion_artifact'] as num?)?.toDouble(),
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
            ] else if (latestVitalsAsync.valueOrNull != null)
              _buildLatestVitalsCard(latestVitalsAsync.valueOrNull!, theme)
            else
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
            const SizedBox(height: 16),
            _buildVitalsSummaryCard(
                vitals, latestVitalsAsync.valueOrNull, theme),
            const SizedBox(height: 16),
            _buildLiveChartCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestVitalsCard(VitalsRecord latest, ThemeData theme) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                VitalSignGauge(
                  label: 'BP Systolic',
                  value: latest.systolicBP,
                  unit: 'mmHg',
                  normalRange: Range(90, 120),
                  icon: Icons.speed,
                ),
                VitalSignGauge(
                  label: 'BP Diastolic',
                  value: latest.diastolicBP,
                  unit: 'mmHg',
                  normalRange: Range(60, 80),
                  icon: Icons.speed,
                ),
                VitalSignGauge(
                  label: 'Temperature',
                  value: latest.temperature,
                  unit: '°C',
                  normalRange: Range(36.0, 37.5),
                  icon: Icons.thermostat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSummaryCard(
    Map<String, dynamic>? vitals,
    VitalsRecord? latest,
    ThemeData theme,
  ) {
    final bp = vitals?['systolic_bp'] ?? latest?.systolicBP;
    final bpDiastolic = vitals?['diastolic_bp'] ?? latest?.diastolicBP;
    final temp = vitals?['temperature'] ?? latest?.temperature;
    final respiratory = vitals?['respiratory_rate'] ?? latest?.respiratoryRate;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BP & Temperature', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('ضغط الدم',
                    bp != null ? '$bp/${bpDiastolic ?? '--'}' : '--', 'mmHg'),
                _buildMetric(
                    'درجة الحرارة', temp != null ? '$temp°C' : '--', ''),
                _buildMetric(
                    'معدل التنفس',
                    respiratory != null
                        ? '${respiratory.toStringAsFixed(0)}'
                        : '--',
                    '/min'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: NeuroColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: NeuroColors.textSecondary)),
        if (unit.isNotEmpty)
          Text(unit,
              style: const TextStyle(
                  fontSize: 10, color: NeuroColors.textSecondary)),
      ],
    );
  }

  Widget _buildLiveChartCard(ThemeData theme) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Heart Rate Trend',
                    style: theme.textTheme.titleSmall),
                if (_heartRateHistory.isNotEmpty)
                  Text(
                    '${_heartRateHistory.last.y.toStringAsFixed(0)} bpm',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: NeuroColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_heartRateHistory.length < 2)
              SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'بانتظار وصول بيانات حية...',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: NeuroColors.textSecondary),
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    minY: _chartMinY(),
                    maxY: _chartMaxY(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: NeuroColors.textPrimary.withValues(alpha: 0.06),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _heartRateHistory,
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: NeuroColors.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: NeuroColors.primary.withValues(alpha: 0.15),
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

  double _chartMinY() {
    final values = _heartRateHistory.map((s) => s.y);
    final min = values.reduce(math.min);
    return (min - 10).clamp(0, double.infinity);
  }

  double _chartMaxY() {
    final values = _heartRateHistory.map((s) => s.y);
    final max = values.reduce(math.max);
    return max + 10;
  }

  String _formatLastUpdate(
    Map<String, dynamic>? vitals,
    VitalsRecord? latest,
  ) {
    final ts = vitals?['timestamp'];
    if (ts is String) {
      try {
        final dt = DateTime.parse(ts).toLocal();
        return 'آخر تحديث: ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    if (latest?.timestamp != null) {
      final dt = latest!.timestamp!.toLocal();
      return 'آخر تحديث: ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NeuroColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: NeuroColors.textSecondary)),
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
