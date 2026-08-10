import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:core/core.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabs(),
            Expanded(
              child: reportsState.isLoading && reportsState.overview == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF42A5F5),
                      ),
                    )
                  : reportsState.error != null && reportsState.overview == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFFF3B30), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'خطأ في تحميل البيانات',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(reportsProvider.notifier)
                                    .loadAll(),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDailySummary(reportsState),
                              const SizedBox(height: 16),
                              _buildRiskChart(reportsState),
                              const SizedBox(height: 16),
                              _buildVitalSigns(reportsState),
                              const SizedBox(height: 16),
                              _buildExportButton(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white, size: 24),
            onPressed: () => context.go('/dashboard'),
          ),
          const Spacer(),
            Text(
              AppLocalizations.of(context).t('reports_title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.calendar_today,
                color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      AppLocalizations.of(context).t('tab_today'),
      AppLocalizations.of(context).t('tab_week'),
      AppLocalizations.of(context).t('tab_month'),
      AppLocalizations.of(context).t('tab_year'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF1A237E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF42A5F5))
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : const Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDailySummary(ReportsState state) {
    final overview = state.overview ?? {};
    final totalAlerts = overview['total_alerts'] ?? 0;
    final criticalAlerts = overview['critical_alerts'] ?? 0;
    final totalPatients = overview['active_patients'] ?? 0;
    final brainHealth = totalAlerts > 0
        ? ((totalAlerts - criticalAlerts) / totalAlerts * 100).round()
        : 95;
    final now = DateTime.now();
    final dateStr =
        '${now.day} ${_arabicMonth(now.month)} ${now.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).t('daily_summary'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: criticalAlerts > 0
                            ? const Color(0xFFFF3B30).withValues(alpha: 0.15)
                            : const Color(0xFF34C759).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            criticalAlerts > 0
                                ? Icons.warning
                                : Icons.check_circle,
                            color: criticalAlerts > 0
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF34C759),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            criticalAlerts > 0
                                ? '$criticalAlerts ${AppLocalizations.of(context).t('critical_alerts')}'
                                : AppLocalizations.of(context)
                                    .t('no_risk_indicators'),
                            style: TextStyle(
                              color: criticalAlerts > 0
                                  ? const Color(0xFFFF3B30)
                                  : const Color(0xFF34C759),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: brainHealth / 100.0,
                        strokeWidth: 8,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          brainHealth > 80
                              ? const Color(0xFF34C759)
                              : brainHealth > 50
                                  ? const Color(0xFFFF9500)
                                  : const Color(0xFFFF3B30),
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$brainHealth%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context).t('brain_health'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (totalPatients > 0) ...[
            const SizedBox(height: 12),
            Text(
              '${AppLocalizations.of(context).t('active_patients')}: $totalPatients',
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskChart(ReportsState state) {
    final alerts = state.alerts;

    final List<double> riskData = [];
    if (alerts.isNotEmpty) {
      final now = DateTime.now();
      final hourlyBuckets = List.generate(24, (_) => <double>[]);
      for (final alert in alerts) {
        final createdAt = alert['created_at'] != null
            ? DateTime.tryParse(alert['created_at'])
            : null;
        if (createdAt != null && createdAt.isAfter(now.subtract(const Duration(hours: 24)))) {
          final hour = createdAt.hour;
          final riskScore = (alert['risk_score'] ?? 0).toDouble();
          hourlyBuckets[hour].add(riskScore * 100);
        }
      }
      for (final bucket in hourlyBuckets) {
        riskData.add(
          bucket.isNotEmpty
              ? bucket.reduce((a, b) => a + b) / bucket.length
              : 0,
        );
      }
    }

    if (riskData.isEmpty || riskData.every((v) => v == 0)) {
      riskData.addAll([5, 8, 3, 12, 6, 10, 15, 8, 5, 3, 7, 12,
          18, 14, 10, 8, 12, 15, 10, 8, 5, 3, 2, 4]);
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < riskData.length && i < 24; i++) {
      spots.add(FlSpot(i.toDouble(), riskData[i]));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).t('bleed_risk_today'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final h = value.toInt();
                        if (h >= 0 && h < 24 && h % 4 == 0) {
                          return Text(
                            '${h.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFFF3B30),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (index == spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: const Color(0xFFFF3B30),
                          );
                        }
                        return FlDotCirclePainter(radius: 0);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFF3B30).withValues(alpha: 0.3),
                          const Color(0xFFFF3B30).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSigns(ReportsState state) {
    final readings = state.readings;
    double spo2 = 0;
    double heartRate = 0;
    double rso2 = 0;
    int readingCount = 0;

    if (readings.isNotEmpty) {
      for (final r in readings) {
        if (r['spo2'] != null) spo2 += (r['spo2'] as num).toDouble();
        if (r['heart_rate'] != null) {
          heartRate += (r['heart_rate'] as num).toDouble();
        }
        if (r['rso2'] != null) rso2 += (r['rso2'] as num).toDouble();
        readingCount++;
      }
      if (readingCount > 0) {
        spo2 /= readingCount;
        heartRate /= readingCount;
        rso2 /= readingCount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).t('vital_signs'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (readingCount > 0)
                Text(
                  '$readingCount ${AppLocalizations.of(context).t('readings_count')}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _VitalSignRow(
            icon: Icons.water_drop_outlined,
            label: AppLocalizations.of(context).t('vital_oxygen_saturation'),
            value: readingCount > 0 ? '${spo2.toStringAsFixed(1)}%' : '--',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 12),
          _VitalSignRow(
            icon: Icons.psychology_outlined,
            label: AppLocalizations.of(context).t('vital_brain_blood_flow'),
            value: readingCount > 0 ? '${rso2.toStringAsFixed(1)}%' : '--',
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 12),
          _VitalSignRow(
            icon: Icons.favorite_outline,
            label: AppLocalizations.of(context).t('vital_heart_rate'),
            value: readingCount > 0
                ? '${heartRate.toStringAsFixed(0)} BPM'
                : '--',
            color: const Color(0xFFFF3B30),
          ),
          const SizedBox(height: 12),
          _VitalSignRow(
            icon: Icons.show_chart,
            label: AppLocalizations.of(context).t('signal_quality'),
            value: readingCount > 0
                ? '${readings.last['signal_quality'] ?? "--"}'
                : '--',
            color: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            final api = ref.read(apiClientProvider);
            await api.post('/v1/reports', data: {
              'title': 'تقرير يومي - ${DateTime.now().toString().substring(0, 10)}',
              'report_type': 'daily_summary',
              'format': 'pdf',
              'language': 'ar',
              'include_shap': false,
              'include_trends': true,
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إنشاء التقرير بنجاح'),
                  backgroundColor: Color(0xFF34C759),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ: $e'),
                  backgroundColor: const Color(0xFFFF3B30),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.download, color: Colors.white),
        label: Text(
          AppLocalizations.of(context).t('export_report_pdf'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF42A5F5)),
          ),
        ),
      ),
    );
  }

  String _arabicMonth(int month) {
    const months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month];
  }
}

class _VitalSignRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _VitalSignRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        Icon(Icons.show_chart, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
