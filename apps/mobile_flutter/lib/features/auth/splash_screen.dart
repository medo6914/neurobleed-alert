import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
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
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _glowController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _textController.forward();
  }

  void _navigate(AuthStatus status) {
    if (!mounted) return;
    switch (status) {
      case AuthStatus.authenticated:
        final role = ref.read(authStateProvider).user?.role.name;
        context.go(role == 'super_admin' ? '/admin' : '/dashboard');
      case AuthStatus.onboarding:
        context.go('/onboarding');
      case AuthStatus.unauthenticated:
        context.go('/login');
      case AuthStatus.unknown:
        break;
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
    void maybeNavigate(AuthStatus status) {
      final guard = ref.read(authGuardProvider);
      if (guard.isInitialized && status != AuthStatus.unknown) {
        _navigate(status);
      }
    }

    ref.listen<AuthState>(authStateProvider, (_, state) {
      maybeNavigate(state.status);
    });
    ref.listen<AuthGuard>(authGuardProvider, (_, __) {
      maybeNavigate(ref.read(authStateProvider).status);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      maybeNavigate(ref.read(authStateProvider).status);
    });
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
          style: NeuroTypography.body.copyWith(
            color: NeuroColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
