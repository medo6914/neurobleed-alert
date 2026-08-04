import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _textController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _glowOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ));

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _glowController.repeat(reverse: true);
    
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuroColors.bgPrimary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NeuroColors.bgPrimary,
              NeuroColors.headerGradTop,
              NeuroColors.bgPrimary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: child,
                    ),
                  );
                },
                child: _buildLogo(),
              ),
              const SizedBox(height: NeuroSpacing.xxl),
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _glowOpacity.value,
                    child: child,
                  );
                },
                child: _buildGlowEffect(),
              ),
              const SizedBox(height: NeuroSpacing.xxl),
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: _buildText(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAEE4FF).withValues(alpha: 0.25),
            blurRadius: 60,
            spreadRadius: 15,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Icon(
            Icons.psychology_outlined,
            size: 80,
            color: Color(0xFFAEE4FF),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF10265A).withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Neuro',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: NeuroColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'Bleed',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: NeuroColors.critical,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NeuroSpacing.sm),
        Text(
          '— ALERT —',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: NeuroColors.critical,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: NeuroSpacing.lg),
        Text(
          'نظام تقييم خطر النزيف الدماغي',
          style: NeuroTypography.body?.copyWith(
            color: NeuroColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
