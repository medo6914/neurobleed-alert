import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final patientAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/analytics/patients');
  final data = response.data;
  if (data is Map) return data.cast<String, dynamic>();
  return <String, dynamic>{};
});

class PatientAnalyticsScreen extends ConsumerWidget {
  const PatientAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientAnalyticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تحليلات المرضى')),
      body: async.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(
          title: 'خطأ في تحميل التحليلات',
          message: '$e',
          onRetry: () => ref.invalidate(patientAnalyticsProvider),
        ),
        data: (data) => SingleChildScrollView(
          padding: EdgeInsets.all(NeuroSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نظرة عامة',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    label: 'الإجمالي',
                    value: '${data['total'] ?? 0}',
                    color: NeuroColors.chartBlue,
                  ),
                ),
                SizedBox(width: NeuroSpacing.sm),
                Expanded(
                  child: _StatCard(
                    label: 'النشطون',
                    value: '${data['active'] ?? 0}',
                    color: NeuroColors.low,
                  ),
                ),
              ]),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                  child: _StatCard(
                    label: 'قبول اليوم',
                    value: '${data['admitted_today'] ?? 0}',
                    color: NeuroColors.medium,
                  ),
                ),
                SizedBox(width: NeuroSpacing.sm),
                Expanded(
                  child: _StatCard(
                    label: 'خروج اليوم',
                    value: '${data['discharged_today'] ?? 0}',
                    color: NeuroColors.critical,
                  ),
                ),
              ]),
              SizedBox(height: NeuroSpacing.lg),
              Text('التركيبة السكانية',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                  child: _DemographicTile(
                    icon: Icons.male,
                    label: 'ذكور',
                    value: '${data['male'] ?? 0}',
                    color: NeuroColors.chartBlue,
                  ),
                ),
                SizedBox(width: NeuroSpacing.sm),
                Expanded(
                  child: _DemographicTile(
                    icon: Icons.female,
                    label: 'إناث',
                    value: '${data['female'] ?? 0}',
                    color: NeuroColors.icp,
                  ),
                ),
              ]),
              SizedBox(height: NeuroSpacing.sm),
              Row(children: [
                Expanded(
                  child: _DemographicTile(
                    icon: Icons.cake,
                    label: 'متوسط العمر',
                    value:
                        '${_asDouble(data['average_age']).toStringAsFixed(1)}',
                    color: NeuroColors.temperature,
                  ),
                ),
                SizedBox(width: NeuroSpacing.sm),
                Expanded(
                  child: _DemographicTile(
                    icon: Icons.access_time,
                    label: 'متوسط الإقامة',
                    value:
                        '${_asDouble(data['average_length_of_stay_days']).toStringAsFixed(1)} يوم',
                    color: NeuroColors.info,
                  ),
                ),
              ]),
              _buildAdmissionsChart(data, theme),
              _buildDepartmentStats(data, theme),
              _buildPrediction(data, theme),
            ],
          ),
        ),
      ),
    );
  }

  double _asDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;

  Widget _buildAdmissionsChart(Map<String, dynamic> data, ThemeData theme) {
    final admissions = data['admissions_by_month'];
    if (admissions is! List || admissions.isEmpty) {
      return const SizedBox.shrink();
    }

    final labels = <String>[];
    final values = <double>[];
    for (final item in admissions) {
      if (item is Map) {
        final label = item['month'] ?? item['label'] ?? '';
        final value = (item['count'] as num?)?.toDouble() ?? 0;
        labels.add('$label');
        values.add(value);
      }
    }
    if (values.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: NeuroSpacing.lg),
        Text('القبول الشهري',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: NeuroSpacing.sm),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(NeuroSpacing.md),
            child: SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: values.reduce((a, b) => a < b ? a : b) - 1,
                  maxY: values.reduce((a, b) => a > b ? a : b) + 1,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: NeuroColors.chartGrid,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              labels[idx],
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < values.length; i++)
                          FlSpot(i.toDouble(), values[i]),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: NeuroColors.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: NeuroColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentStats(Map<String, dynamic> data, ThemeData theme) {
    final departments = data['by_department'];
    if (departments is! List || departments.isEmpty) {
      return const SizedBox.shrink();
    }
    final counts = departments.map((d) {
      final c = (d['count'] as num?)?.toDouble() ??
          (d['patient_count'] as num?)?.toDouble() ??
          0.0;
      return c;
    }).toList();
    final avg =
        counts.isEmpty ? 0.0 : counts.reduce((a, b) => a + b) / counts.length;
    final high = counts.isEmpty ? 0.0 : counts.reduce((a, b) => a > b ? a : b);
    final low = counts.isEmpty ? 0.0 : counts.reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: NeuroSpacing.lg),
        Text('إحصاءات الأقسام',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: NeuroSpacing.sm),
        Row(children: [
          Expanded(
            child: _StatCard(
              label: 'متوسط',
              value: avg.toStringAsFixed(1),
              color: NeuroColors.chartBlue,
            ),
          ),
          SizedBox(width: NeuroSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'أعلى قسم',
              value: high.toStringAsFixed(0),
              color: NeuroColors.critical,
            ),
          ),
        ]),
        SizedBox(height: NeuroSpacing.sm),
        Row(children: [
          Expanded(
            child: _StatCard(
              label: 'أقل قسم',
              value: low.toStringAsFixed(0),
              color: NeuroColors.low,
            ),
          ),
          SizedBox(width: NeuroSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'عدد الأقسام',
              value: '${departments.length}',
              color: NeuroColors.medium,
            ),
          ),
        ]),
        SizedBox(height: NeuroSpacing.sm),
        ...departments.map((d) => Padding(
              padding: EdgeInsets.only(bottom: NeuroSpacing.xs),
              child: AppCard(
                child: Padding(
                  padding: EdgeInsets.all(NeuroSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${d['name'] ?? d['department'] ?? 'غير معروف'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${d['count'] ?? d['patient_count'] ?? 0}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPrediction(Map<String, dynamic> data, ThemeData theme) {
    final admissions = data['admissions_by_month'];
    if (admissions is! List || admissions.length < 2) {
      return const SizedBox.shrink();
    }
    final values = admissions
        .map((m) => (m is Map ? ((m['count'] as num?)?.toDouble() ?? 0) : 0.0))
        .toList();
    final last = values[values.length - 1];
    final prev = values[values.length - 2];
    final change = prev == 0 ? 0.0 : ((last - prev) / prev) * 100;
    final predicted = last * (1 + (change / 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: NeuroSpacing.lg),
        Text('توقع الشهر القادم',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: NeuroSpacing.sm),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(NeuroSpacing.md),
            child: Row(
              children: [
                Icon(
                  change >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: change >= 0 ? NeuroColors.critical : NeuroColors.low,
                  size: 32,
                ),
                const SizedBox(width: NeuroSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '~${predicted.round()} قبول متوقع',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'اتجاه ${change >= 0 ? 'تصاعدي' : 'تنازلي'} '
                        '(${change.abs().toStringAsFixed(1)}% مقارنة بالشهر السابق)',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(NeuroSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _DemographicTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DemographicTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Padding(
        padding: EdgeInsets.all(NeuroSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(NeuroRadius.sm),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(width: NeuroSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
