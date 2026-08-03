import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

class SosScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const SosScreen({super.key, this.patientId});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen>
    with SingleTickerProviderStateMixin {
  bool _isEmergencyActive = false;
  int _countdown = 10;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerEmergency() {
    setState(() {
      _isEmergencyActive = true;
      _countdown = 10;
    });
    _pulseController.repeat(reverse: true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
          _sendEmergency();
        }
      });
    });
  }

  void _cancelEmergency() {
    _countdownTimer?.cancel();
    _pulseController.stop();
    setState(() {
      _isEmergencyActive = false;
      _countdown = 10;
    });
  }

  void _sendEmergency() {
    _pulseController.stop();
    setState(() {
      _isEmergencyActive = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال إشعار الطوارئ'),
        backgroundColor: NeuroColors.critical,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuroColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Center(
                child: _isEmergencyActive ? _buildEmergencyActive() : _buildEmergencyButton(),
              ),
            ),
            _buildBottomActions(),
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
            icon: const Icon(Icons.arrow_back_ios, color: NeuroColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'حالة الطوارئ',
              style: NeuroTypography.h1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: _triggerEmergency,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    NeuroColors.critical,
                    Color(0xFF8B0000),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: NeuroColors.critical.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emergency,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: NeuroSpacing.sm),
                  Text(
                    'SOS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: NeuroSpacing.xl),
        Text(
          'اضغط للطوارئ',
          style: NeuroTypography.h3?.copyWith(color: NeuroColors.textSecondary),
        ),
        const SizedBox(height: NeuroSpacing.sm),
        Text(
          'سيتم إرسال إشعار طوارئ مع موقعك',
          style: NeuroTypography.caption,
        ),
      ],
    );
  }

  Widget _buildEmergencyActive() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NeuroColors.critical.withValues(alpha: 0.2),
            border: Border.all(color: NeuroColors.critical, width: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_countdown',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'ثانية',
                style: NeuroTypography.caption?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: NeuroSpacing.xl),
        Text(
          'جاري إرسال إشعار الطوارئ...',
          style: NeuroTypography.h3?.copyWith(color: NeuroColors.critical),
        ),
        const SizedBox(height: NeuroSpacing.sm),
        Text(
          'سيتم إرسال موقعك تلقائياً',
          style: NeuroTypography.caption,
        ),
        const SizedBox(height: NeuroSpacing.xl),
        AppButton(
          label: 'إلغاء',
          icon: Icons.cancel,
          onPressed: _cancelEmergency,
          variant: ButtonVariant.secondary,
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: const BoxDecoration(
        color: NeuroColors.bgCard,
        border: Border(
          top: BorderSide(color: NeuroColors.navActive, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              Icons.phone,
              'اتصال طوارئ',
              NeuroColors.critical,
              () {},
            ),
          ),
          const SizedBox(width: NeuroSpacing.md),
          Expanded(
            child: _buildActionCard(
              Icons.local_hospital,
              'أقرب مستشفى',
              NeuroColors.primary,
              () => context.push('/map'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(NeuroSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: NeuroSpacing.sm),
            Text(
              label,
              style: NeuroTypography.caption?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
