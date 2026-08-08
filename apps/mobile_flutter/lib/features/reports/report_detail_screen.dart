import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String? reportId;

  const ReportDetailScreen({super.key, this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuroColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(NeuroSpacing.lg),
                child: Column(
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildBleedProbabilityCard(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildAiAnalysisCard(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildDailyRecommendations(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildTimeline(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildShareButton(),
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
        NeuroSpacing.lg,
        MediaQuery.of(context).padding.top + NeuroSpacing.sm,
        NeuroSpacing.lg,
        NeuroSpacing.sm,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NeuroColors.headerGradTop, NeuroColors.headerGradBottom],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: NeuroColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'تفاصيل التقرير',
              style: NeuroTypography.h1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeuroSpacing.lg,
        vertical: NeuroSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.chip),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, color: NeuroColors.primary, size: 20),
          const SizedBox(width: NeuroSpacing.sm),
          Text(
            '18 يوليو 2026',
            style: NeuroTypography.bodyMedium,
          ),
          const SizedBox(width: NeuroSpacing.sm),
          Icon(Icons.arrow_drop_down, color: NeuroColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildBleedProbabilityCard() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NeuroColors.cardGradTop, NeuroColors.cardGradBottom],
        ),
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        boxShadow: const [NeuroShadows.card],
      ),
      child: Row(
        children: [
          _buildProbabilityGauge(0.18),
          const SizedBox(width: NeuroSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'احتمالية النزيف',
                  style: NeuroTypography.h3
                      ?.copyWith(color: NeuroColors.textSecondary),
                ),
                const SizedBox(height: NeuroSpacing.sm),
                Text(
                  '18%',
                  style: NeuroTypography.display?.copyWith(
                    fontSize: 32,
                    color: NeuroColors.critical,
                  ),
                ),
                const SizedBox(height: NeuroSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NeuroSpacing.sm,
                    vertical: NeuroSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: NeuroColors.low.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(NeuroRadius.badge),
                  ),
                  child: Text(
                    'الحد الطبيعي أقل من 25%',
                    style: NeuroTypography.caption
                        ?.copyWith(color: NeuroColors.low),
                  ),
                ),
                const SizedBox(height: NeuroSpacing.xs),
                Text(
                  'الحالة: منخفضة',
                  style: NeuroTypography.h3
                      ?.copyWith(color: NeuroColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityGauge(double value) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 10,
              backgroundColor: NeuroColors.bgInput,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(NeuroColors.critical),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).toInt()}%',
                  style: NeuroTypography.display?.copyWith(fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: NeuroColors.primary, size: 24),
              const SizedBox(width: NeuroSpacing.sm),
              Text(
                'تحليل الذكاء الاصطناعي',
                style: NeuroTypography.h3,
              ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.md),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: NeuroColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(NeuroRadius.md),
            ),
            child: const Icon(
              Icons.psychology,
              color: NeuroColors.primaryLight,
              size: 30,
            ),
          ),
          const SizedBox(height: NeuroSpacing.md),
          Text(
            'لا توجد مؤشرات خطرية',
            style: NeuroTypography.h3?.copyWith(color: NeuroColors.textPrimary),
          ),
          const SizedBox(height: NeuroSpacing.sm),
          Text(
            'البيانات الحالية تشير إلى حالة مستقرة للدماغ.',
            style: NeuroTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecommendations() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نصائح اليوم',
            style: NeuroTypography.h3,
          ),
          const SizedBox(height: NeuroSpacing.md),
          _buildRecommendation('اشرب الماء بانتظام', true),
          _buildRecommendation('احصل على قسط كافٍ من النوم', true),
          _buildRecommendation('تجنب الإجهاد والضغط النفسي', true),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NeuroSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? NeuroColors.low : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? NeuroColors.low : NeuroColors.navInactive,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check,
                    color: NeuroColors.textPrimary, size: 16)
                : null,
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Text(text, style: NeuroTypography.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: NeuroColors.primary, size: 24),
              const SizedBox(width: NeuroSpacing.sm),
              Text(
                'الخط الزمني الطبي',
                style: NeuroTypography.h3,
              ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.lg),
          _buildTimelineItem(
            icon: Icons.monitor_heart_outlined,
            title: 'قراءة القياسات الحيوية',
            subtitle: 'معدل ضغط الدم: 120/80 - معدل النبض: 72',
            time: '08:00 صباحاً',
            color: NeuroColors.low,
            isLast: false,
          ),
          _buildTimelineItem(
            icon: Icons.psychology_outlined,
            title: 'تحليل الذكاء الاصطناعي',
            subtitle: 'اكتمل تقييم خطر النزيف - احتمال 18%',
            time: '08:05 صباحاً',
            color: NeuroColors.info,
            isLast: false,
          ),
          _buildTimelineItem(
            icon: Icons.health_and_safety_outlined,
            title: 'مراجعة الطبيب',
            subtitle: 'مراجعة يومية مجدولة - الحالة مستقرة',
            time: '09:30 صباحاً',
            color: NeuroColors.primary,
            isLast: false,
          ),
          _buildTimelineItem(
            icon: Icons.description_outlined,
            title: 'إصدار التقرير',
            subtitle: 'تم إنشاء التقرير اليومي ورقمه NB-2026-0718',
            time: '10:00 صباحاً',
            color: NeuroColors.critical,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: NeuroColors.chartGrid,
                  ),
                ),
            ],
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : NeuroSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: NeuroTypography.h3?.copyWith(
                            color: NeuroColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: NeuroTypography.caption?.copyWith(
                          color: NeuroColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NeuroSpacing.xs),
                  Text(
                    subtitle,
                    style: NeuroTypography.caption?.copyWith(
                      color: NeuroColors.textBody,
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

  Widget _buildShareButton() {
    return AppButton(
      label: 'مشاركة التقرير',
      icon: Icons.share,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ رابط التقرير'),
            backgroundColor: NeuroColors.low,
          ),
        );
      },
      variant: ButtonVariant.primary,
    );
  }
}
