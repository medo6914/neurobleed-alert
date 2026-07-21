import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authStateProvider.notifier).resetPassword(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
          );
      final authState = ref.read(authStateProvider);
      if (authState.error == null) {
        setState(() => _isSuccess = true);
      }
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
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(NeuroSpacing.xl),
          child: SizedBox(
            width: contentWidth,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: NeuroColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(NeuroRadius.xxl),
                    ),
                    child: const Icon(
                      Icons.lock_reset_outlined,
                      size: 40,
                      color: NeuroColors.primary,
                    ),
                  ),
                  const SizedBox(height: NeuroSpacing.xl),
                  Text(
                    'إعادة تعيين كلمة المرور',
                    style: theme.headlineMedium,
                  ),
                  const SizedBox(height: NeuroSpacing.sm),
                  Text(
                    'أدخل رمز التحقق الذي تلقيته على بريدك الإلكتروني مع كلمة المرور الجديدة',
                    style: theme.bodyMedium?.copyWith(
                      color: NeuroColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NeuroSpacing.xxl),
                  AppInput(
                    label: 'البريد الإلكتروني',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'البريد الإلكتروني مطلوب';
                      return null;
                    },
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  AppInput(
                    label: 'رمز التحقق',
                    hint: 'أدخل الرقم المكون من 6 أرقام',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'رمز التحقق مطلوب';
                      if (v.length < 6) return 'رمز التحقق غير مكتمل';
                      return null;
                    },
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  AppInput(
                    label: 'كلمة المرور الجديدة',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                      if (v.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                      return null;
                    },
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  AppInput(
                    label: 'تأكيد كلمة المرور الجديدة',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  if (authState.error != null) ...[
                    const SizedBox(height: NeuroSpacing.md),
                    AlertBanner(
                      severity: AlertSeverity.critical,
                      title: authState.error!,
                    ),
                  ],
                  if (_isSuccess) ...[
                    const SizedBox(height: NeuroSpacing.md),
                    const AlertBanner(
                      severity: AlertSeverity.stable,
                      title: 'تم إعادة تعيين كلمة المرور بنجاح',
                    ),
                  ],
                  const SizedBox(height: NeuroSpacing.xl),
                  AppButton(
                    label: 'إعادة تعيين كلمة المرور',
                    onPressed: _onSubmit,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('العودة إلى تسجيل الدخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
