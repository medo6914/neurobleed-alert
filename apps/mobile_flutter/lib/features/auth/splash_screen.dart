import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../../app/providers/app_providers.dart';
import '../../core/auth/auth_provider.dart';
import '../../firebase_options.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _fadeAnim;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('[SPLASH] initState');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    debugPrint('[SPLASH] _initApp started');
    try {
      debugPrint('[SPLASH] Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));
        debugPrint('[SPLASH] Firebase ready');
      } on TimeoutException {
        debugPrint('[SPLASH] Firebase init timed out, continuing without it');
      } catch (e) {
        debugPrint('[SPLASH] Firebase init error: $e');
      }

      await _checkAuth();
    } catch (e) {
      debugPrint('[SPLASH] _initApp error: $e');
      if (!mounted) return;
      setState(() => _error = 'Failed to initialize');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/login');
    }
  }

  Future<void> _checkAuth() async {
    debugPrint('[SPLASH] _checkAuth started');
    try {
      final storage = SecureStorageService();
      final hasToken = await storage
          .hasToken()
          .timeout(const Duration(seconds: 5));
      debugPrint('[SPLASH] hasToken: $hasToken');
      if (hasToken) {
        ref.read(authGuardProvider).setAuthenticated(true);
        debugPrint('[SPLASH] Token found, set authenticated');
      } else {
        ref.read(authGuardProvider).setAuthenticated(false);
        debugPrint('[SPLASH] No token, set unauthenticated');
      }
    } catch (e) {
      debugPrint('[SPLASH] _checkAuth error: $e');
      ref.read(authGuardProvider).setAuthenticated(false);
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final isAuth = ref.read(authGuardProvider).isAuthenticated;
    debugPrint('[SPLASH] Auth status: $isAuth, navigating...');
    if (isAuth) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
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
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Color(0xFF251E44),
              Color(0xFF10265A),
              NeuroColors.bgPrimary,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brain scan glow visualization
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseAnim.value * 0.08);
                  final opacity = 0.6 + (_pulseAnim.value * 0.4);
                  return SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFAEE4FF).withValues(alpha: opacity * 0.3),
                                const Color(0xFF251E44).withValues(alpha: opacity * 0.1),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        // Brain logo (extracted from reference splash-brain-scan.jpg)
                        Transform.scale(
                          scale: scale,
                          child: Image.asset(
                            'assets/images/logo_brain.png',
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stack) => Icon(
                              Icons.psychology_outlined,
                              size: 64,
                              color: Color(0xFFAEE4FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: NeuroSpacing.xl),
              // App title
              Text(
                'NeuroBleed Alert',
                style: NeuroTypography.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: NeuroSpacing.sm),
              // Tagline
              Text(
                'نظام تقييم خطر النزيف الدماغي',
                style: NeuroTypography.bodyMedium?.copyWith(
                  color: NeuroColors.textBody,
                ),
              ),
              const SizedBox(height: NeuroSpacing.xxxl),
              // Loading indicator
              if (_error == null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      NeuroColors.primaryLight.withValues(alpha: 0.8),
                    ),
                  ),
                )
              else
                Text(
                  _error!,
                  style: NeuroTypography.bodyMedium?.copyWith(
                    color: NeuroColors.critical,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
