import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

final reportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/reports/', queryParameters: {
    'per_page': 200,
  });
  final data = response.data;
  if (data is List) return data.cast<Map<String, dynamic>>();
  if (data is Map && data['items'] is List) {
    return (data['items'] as List).cast<Map<String, dynamic>>();
  }
  return [];
});

enum ReportPeriod { all, daily, weekly, monthly }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.all;

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير السريرية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reportsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reportsProvider),
        child: reportsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('تعذر تحميل التقارير',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('$err', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(reportsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
          data: (reports) {
            final filtered = _filterByPeriod(reports);
            if (reports.isEmpty) {
              return _buildEmpty(theme);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodChips(),
                const SizedBox(height: 16),
                _buildReportChart(filtered, theme),
                const SizedBox(height: 16),
                ...filtered.map((report) => _buildReportCard(report, theme)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('لا توجد تقارير بعد', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('ستظهر التقارير السريرية هنا',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterByPeriod(
      List<Map<String, dynamic>> reports) {
    if (_period == ReportPeriod.all) return reports;
    final now = DateTime.now();
    final cutoff = switch (_period) {
      ReportPeriod.daily => now.subtract(const Duration(days: 1)),
      ReportPeriod.weekly => now.subtract(const Duration(days: 7)),
      ReportPeriod.monthly => now.subtract(const Duration(days: 30)),
      ReportPeriod.all => now,
    };
    return reports.where((r) {
      final created = DateTime.tryParse(r['created_at'] as String? ?? '');
      return created != null && created.isAfter(cutoff);
    }).toList();
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final p in ReportPeriod.values) ...[
            ChoiceChip(
              label: Text(_periodLabel(p)),
              selected: _period == p,
              onSelected: (_) => setState(() => _period = p),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _periodLabel(ReportPeriod p) {
    switch (p) {
      case ReportPeriod.all:
        return 'الكل';
      case ReportPeriod.daily:
        return 'يومي';
      case ReportPeriod.weekly:
        return 'أسبوعي';
      case ReportPeriod.monthly:
        return 'شهري';
    }
  }

  Widget _buildReportChart(
      List<Map<String, dynamic>> reports, ThemeData theme) {
    if (reports.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final days = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      days.add(
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    }
    final counts = days
        .map((d) => reports.where((r) {
              final created =
                  DateTime.tryParse(r['created_at'] as String? ?? '');
              return created != null &&
                  created.year == d.year &&
                  created.month == d.month &&
                  created.day == d.day;
            }).length)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التقارير خلال آخر 7 أيام',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: counts.isEmpty
                      ? 1
                      : (counts.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${days[idx].day}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < counts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            color: NeuroColors.primary,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
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

  Widget _buildReportCard(Map<String, dynamic> report, ThemeData theme) {
    final title = report['title'] as String? ?? 'تقرير بدون عنوان';
    final status = report['status'] as String? ?? 'unknown';
    final format = report['format'] as String? ?? 'PDF';
    final createdAt = report['created_at'] as String? ?? '';
    final patientId = report['patient_id'] as String? ?? '';
    final riskScore = report['risk_score'];

    IconData icon;
    Color statusColor;
    switch (format.toUpperCase()) {
      case 'HTML':
        icon = Icons.code;
        break;
      case 'DOCX':
        icon = Icons.description;
        break;
      default:
        icon = Icons.picture_as_pdf;
    }
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = NeuroColors.success;
        break;
      case 'generating':
        statusColor = NeuroColors.high;
        break;
      case 'failed':
        statusColor = NeuroColors.critical;
        break;
      default:
        statusColor = NeuroColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: patientId.isNotEmpty
            ? () => context.push('/patients/$patientId')
            : null,
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(icon, color: statusColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                      style: TextStyle(fontSize: 12, color: statusColor)),
                ),
                const SizedBox(width: 8),
                Text(format, style: const TextStyle(fontSize: 12)),
                if (riskScore != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Risk: ${((riskScore as num) * 100).toStringAsFixed(0)}%',
                    style:
                        const TextStyle(fontSize: 12, color: NeuroColors.high),
                  ),
                ],
              ],
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(createdAt, style: const TextStyle(fontSize: 11)),
            ],
            if (patientId.isNotEmpty) ...[
              const SizedBox(height: 2),
              const Text('اضغط لفتح ملف المريض',
                  style: TextStyle(fontSize: 11, color: NeuroColors.info)),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'download') {
              await _downloadReport(report, title);
            } else if (action == 'preview') {
              await _previewReport(report);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'download',
                child: ListTile(
                    leading: Icon(Icons.download), title: Text('تنزيل PDF'))),
            const PopupMenuItem(
                value: 'preview',
                child: ListTile(
                    leading: Icon(Icons.visibility), title: Text('معاينة'))),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReport(
      Map<String, dynamic> report, String title) async {
    final id = report['id'];
    if (id == null) {
      _showSnack('التقرير لا يحتوي على معرّف');
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      final tempDir = await Directory.systemTemp.createTemp('neurobleed_');
      final ext = (report['format'] as String? ?? 'pdf').toLowerCase();
      final savePath =
          '${tempDir.path}/report_${id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await api.download('/v1/reports/$id/download', savePath);
      if (!mounted) return;
      _showSnack('تم تنزيل التقرير، جارٍ الفتح...');
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        _showSnack('تم التنزيل إلى: $savePath');
      }
    } catch (e) {
      _showSnack('فشل تنزيل التقرير: $e');
    }
  }

  Future<void> _previewReport(Map<String, dynamic> report) async {
    final id = report['id'];
    final api = ref.read(apiClientProvider);
    final baseUrl = api.dio.options.baseUrl;
    final uri = Uri.parse('$baseUrl/v1/reports/$id/html');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
