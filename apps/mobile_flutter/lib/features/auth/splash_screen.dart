import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../../app/providers/app_providers.dart';
import '../../core/auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final storage = SecureStorageService();
    final hasToken = await storage.hasToken();
    final authGuard = ref.read(authGuardProvider);
    if (hasToken) {
      try {
        ref.read(authStateProvider);
        authGuard.setAuthenticated(true);
      } catch (_) {
        authGuard.setAuthenticated(false);
      }
    } else {
      authGuard.setAuthenticated(false);
    }
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (hasToken) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = NeuroTypography.textTheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [NeuroColors.primary, NeuroColors.primaryDark],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(NeuroRadius.xxl),
                  boxShadow: const [NeuroShadows.elevated],
                ),
                child: const Center(
                  child: Icon(
                    Icons.monitor_heart_outlined,
                    size: 50,
                    color: NeuroColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: NeuroSpacing.xl),
              Text(
                'NeuroBleed Alert',
                style: theme.displaySmall?.copyWith(
                  color: NeuroColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: NeuroSpacing.sm),
              Text(
                'نظام تقييم خطر النزيف الدماغي',
                style: theme.bodyLarge?.copyWith(
                  color: NeuroColors.textOnPrimary.withAlpha(200),
                ),
              ),
              const SizedBox(height: NeuroSpacing.xxxxl),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    NeuroColors.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
