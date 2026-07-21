import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = NeuroTypography.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final contentWidth = isTablet ? 400.0 : screenWidth;

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NeuroSpacing.xl),
            child: SizedBox(
              width: contentWidth,
              child: AppCard(
                padding: const EdgeInsets.all(NeuroSpacing.xxl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: NeuroColors.primary.withAlpha(20),
                          borderRadius:
                              BorderRadius.circular(NeuroRadius.lg),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_outlined,
                          size: 36,
                          color: NeuroColors.primary,
                        ),
                      ),
                      const SizedBox(height: NeuroSpacing.lg),
                      Text(
                        'NeuroBleed Alert',
                        style: theme.headlineSmall?.copyWith(
                          color: NeuroColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: NeuroSpacing.xs),
                      Text(
                        'نظام تقييم خطر النزيف الدماغي',
                        style: theme.bodySmall?.copyWith(
                          color: NeuroColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: NeuroSpacing.xxl),
                      AppInput(
                        label: 'البريد الإلكتروني',
                        hint: 'example@hospital.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'البريد الإلكتروني مطلوب';
                          if (!v.contains('@')) return 'البريد الإلكتروني غير صحيح';
                          return null;
                        },
                      ),
                      const SizedBox(height: NeuroSpacing.lg),
                      AppInput(
                        label: 'كلمة المرور',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                          if (v.length < 6) return 'كلمة المرور قصيرة جداً';
                          return null;
                        },
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      ),
                      if (authState.error != null) ...[
                        const SizedBox(height: NeuroSpacing.sm),
                        AlertBanner(
                          severity: AlertSeverity.critical,
                          title: authState.error!,
                        ),
                      ],
                      const SizedBox(height: NeuroSpacing.lg),
                      AppButton(
                        label: 'تسجيل الدخول',
                        onPressed: _onLogin,
                        isLoading: authState.isLoading,
                      ),
                      const SizedBox(height: NeuroSpacing.lg),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: NeuroSpacing.md),
                            child: Text('أو',
                                style: theme.bodySmall?.copyWith(
                                    color: NeuroColors.textSecondary)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: NeuroSpacing.lg),
                      AppButton(
                        label: 'تسجيل الدخول بواسطة Google',
                        onPressed: () {
                          ref
                              .read(authStateProvider.notifier)
                              .loginWithGoogle();
                        },
                        variant: ButtonVariant.secondary,
                        icon: Icons.g_mobiledata,
                      ),
                      const SizedBox(height: NeuroSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ليس لديك حساب؟ ',
                              style: theme.bodyMedium?.copyWith(
                                  color: NeuroColors.textSecondary)),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text('إنشاء حساب'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
