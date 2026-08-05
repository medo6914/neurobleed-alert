import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authStateProvider.notifier).forgotPassword(
            _emailController.text.trim(),
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
        title: const Text('نسيت كلمة المرور'),
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
                    'استعادة كلمة المرور',
                    style: theme.headlineMedium,
                  ),
                  const SizedBox(height: NeuroSpacing.sm),
                  Text(
                    'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور',
                    style: theme.bodyMedium?.copyWith(
                      color: NeuroColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NeuroSpacing.xxl),
                  AppInput(
                    label: 'البريد الإلكتروني',
                    hint: 'example@hospital.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'البريد الإلكتروني مطلوب';
                      if (!v.contains('@')) return 'البريد الإلكتروني غير صحيح';
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
                      title: 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني',
                    ),
                  ],
                  const SizedBox(height: NeuroSpacing.xl),
                  AppButton(
                    label: 'إرسال رابط إعادة التعيين',
                    onPressed: _onSubmit,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  TextButton(
                    onPressed: () => context.pop(),
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
