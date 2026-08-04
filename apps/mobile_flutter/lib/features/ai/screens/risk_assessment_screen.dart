import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';

import '../providers/ai_providers.dart';
import '../widgets/ai_widgets.dart';

class RiskAssessmentScreen extends ConsumerStatefulWidget {
  final String patientId;

  const RiskAssessmentScreen({super.key, required this.patientId});

  @override
  ConsumerState<RiskAssessmentScreen> createState() =>
      _RiskAssessmentScreenState();
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
      body: Column(
        children: [
          // Gradient header (reference: #020C23 → #2F3C55)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NeuroColors.headerGradTop,
                  NeuroColors.headerGradBottom,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NeuroSpacing.sm,
                  vertical: NeuroSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: NeuroColors.textBody,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      'Risk Assessment',
                      style: NeuroTypography.h3?.copyWith(
                        color: NeuroColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NeuroSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input card
                  Container(
                    padding: const EdgeInsets.all(NeuroSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          NeuroColors.cardGradTop,
                          NeuroColors.cardGradBottom,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(NeuroRadius.card),
                      boxShadow: const [NeuroShadows.card],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدخال العلامات الحيوية',
                          style: NeuroTypography.h2,
                        ),
                        const SizedBox(height: NeuroSpacing.md),
                        _buildTextField(
                            _hrCtrl, 'Heart Rate (bpm)', Icons.favorite),
                        _buildTextField(
                            _spo2Ctrl, 'SpO2 (%)', Icons.air),
                        _buildTextField(
                            _rso2Ctrl, 'rSO2 (%)', Icons.psychology),
                        _buildTextField(
                            _sbpCtrl, 'Systolic BP (mmHg)', Icons.water_drop),
                        _buildTextField(
                            _dbpCtrl, 'Diastolic BP (mmHg)', Icons.water_drop),
                        _buildTextField(_gcsCtrl, 'GCS Score', Icons.healing),
                        const SizedBox(height: NeuroSpacing.lg),
                        Text(
                          'جودة الإشارة',
                          style: NeuroTypography.bodyMedium,
                        ),
                        Slider(
                          value: _signalQuality,
                          activeColor: NeuroColors.primaryLight,
                          inactiveColor: NeuroColors.chartGrid,
                          onChanged: (v) =>
                              setState(() => _signalQuality = v),
                          min: 0,
                          max: 1,
                          divisions: 20,
                        ),
                        Text(
                          'تشويش الحركة',
                          style: NeuroTypography.bodyMedium,
                        ),
                        Slider(
                          value: _motionArtifact,
                          activeColor: NeuroColors.primaryLight,
                          inactiveColor: NeuroColors.chartGrid,
                          onChanged: (v) =>
                              setState(() => _motionArtifact = v),
                          min: 0,
                          max: 1,
                          divisions: 20,
                        ),
                        const SizedBox(height: NeuroSpacing.sm),
                        AppButton(
                          label: state.isAssessing ? 'جارِ التقييم...' : 'تقييم الخطر',
                          icon: Icons.assessment,
                          onPressed: state.isAssessing ? null : _assess,
                          isLoading: state.isAssessing,
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: NeuroSpacing.md),
                    AlertBanner(
                      severity: AlertSeverity.critical,
                      title: state.error!,
                    ),
                  ],
                  if (result != null) ...[
                    const SizedBox(height: NeuroSpacing.xl),
                    // Risk score gauge card
                    Container(
                      padding: const EdgeInsets.all(NeuroSpacing.lg),
                      decoration: BoxDecoration(
                        color: NeuroColors.bgElevated,
                        borderRadius: BorderRadius.circular(NeuroRadius.card),
                        boxShadow: const [NeuroShadows.card],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'درجة الخطر',
                            style: NeuroTypography.h2,
                          ),
                          const SizedBox(height: NeuroSpacing.md),
                          _RiskGauge(score: result.riskScore),
                          const SizedBox(height: NeuroSpacing.md),
                          _RiskLevelBadge(level: result.riskLevel),
                          const SizedBox(height: NeuroSpacing.sm),
                          Text(
                            'الثقة: ${(result.confidence * 100).toStringAsFixed(1)}%',
                            style: NeuroTypography.caption,
                          ),
                          if (result.trend != null) ...[
                            const SizedBox(height: NeuroSpacing.sm),
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
                                      ? NeuroColors.criticalBright
                                      : result.trend == 'improving'
                                          ? NeuroColors.low
                                          : NeuroColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'التحول: ${result.trend!.toUpperCase()}',
                                  style: NeuroTypography.caption.copyWith(
                                    color: result.trend == 'worsening'
                                        ? NeuroColors.criticalBright
                                        : result.trend == 'improving'
                                            ? NeuroColors.low
                                            : NeuroColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: NeuroSpacing.lg),
                    // Contributing factors card
                    if (result.contributingFactors.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(NeuroSpacing.lg),
                        decoration: BoxDecoration(
                          color: NeuroColors.bgCard,
                          borderRadius: BorderRadius.circular(NeuroRadius.card),
                          boxShadow: const [NeuroShadows.card],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'العوامل المساهمة',
                              style: NeuroTypography.h2,
                            ),
                            const SizedBox(height: NeuroSpacing.md),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: result.contributingFactors
                                  .map((f) =>
                                      ContributingFactorsChip(factor: f))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: NeuroSpacing.lg),
                    // Rules triggered card
                    if (result.rulesTriggered.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(NeuroSpacing.lg),
                        decoration: BoxDecoration(
                          color: NeuroColors.bgCard,
                          borderRadius: BorderRadius.circular(NeuroRadius.card),
                          boxShadow: const [NeuroShadows.card],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'القواعد المُفعّلة',
                              style: NeuroTypography.h2,
                            ),
                            const SizedBox(height: NeuroSpacing.md),
                            ...result.rulesTriggered.map((r) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.rule,
                                        size: 16,
                                        color: NeuroColors.high,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          r,
                                          style: NeuroTypography.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    const SizedBox(height: NeuroSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'النموذج: ${result.modelVersion ?? "N/A"}',
                          style: NeuroTypography.caption,
                        ),
                        Text(
                          'الاستدلال: ${result.inferenceTimeMs.toStringAsFixed(1)}ms',
                          style: NeuroTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: NeuroTypography.bodyLarge?.copyWith(
          color: NeuroColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: NeuroTypography.caption,
          prefixIcon: Icon(icon, color: NeuroColors.textBody, size: 22),
          filled: true,
          fillColor: NeuroColors.bgInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.input),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.input),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.input),
            borderSide: const BorderSide(
              color: NeuroColors.primary,
              width: 2,
            ),
          ),
          isDense: true,
        ),
      ),
    );
  }
}

// ─── Risk Gauge (reference IMG-0194: circular gauge with gradient arc) ──
class _RiskGauge extends StatelessWidget {
  final double score;

  const _RiskGauge({required this.score});

  Color get _color {
    if (score >= 0.7) return NeuroColors.criticalBright;
    if (score >= 0.4) return NeuroColors.high;
    return NeuroColors.low;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _GaugePainter(score: score, color: _color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(score * 100).toStringAsFixed(0)}',
                style: NeuroTypography.displayLarge?.copyWith(
                  fontSize: 56,
                  color: _color,
                ),
              ),
              Text(
                '/ 100',
                style: NeuroTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = -pi / 2;
    final sweepAngle = pi * 2 * score.clamp(0.0, 1.0);

    // Background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = NeuroColors.chartGrid;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      pi * 2,
      false,
      trackPaint,
    );

    // Gradient arc (green → yellow → red)
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + pi * 2,
        colors: [
          NeuroColors.low,
          NeuroColors.medium,
          NeuroColors.high,
          NeuroColors.criticalBright,
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

class _RiskLevelBadge extends StatelessWidget {
  final String level;

  const _RiskLevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final normalized = level.toLowerCase();
    final Color color;
    switch (normalized) {
      case 'critical':
        color = NeuroColors.criticalBright;
        break;
      case 'high':
        color = NeuroColors.high;
        break;
      case 'medium':
        color = NeuroColors.medium;
        break;
      default:
        color = NeuroColors.low;
    }
    final label = normalized == 'critical'
        ? 'حرج'
        : normalized == 'high'
            ? 'مرتفع'
            : normalized == 'medium'
                ? 'متوسط'
                : 'منخفض';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeuroSpacing.lg,
        vertical: NeuroSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(NeuroRadius.chip),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: NeuroTypography.h3?.copyWith(color: color),
      ),
    );
  }
}
