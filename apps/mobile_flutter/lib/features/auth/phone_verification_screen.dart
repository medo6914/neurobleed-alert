import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _sendCode() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authStateProvider.notifier)
          .sendPhoneVerification(_phoneController.text.trim());
      setState(() => _codeSent = true);
    }
  }

  void _verifyCode() {
    if (_codeController.text.trim().length >= 6) {
      ref.read(authStateProvider.notifier).verifyPhone(
            _phoneController.text.trim(),
            _codeController.text.trim(),
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
      appBar: AppBar(
        title: const Text('التحقق من رقم الهاتف'),
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
                      color: NeuroColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(NeuroRadius.xxl),
                    ),
                    child: const Icon(
                      Icons.phone_android_outlined,
                      size: 40,
                      color: NeuroColors.primary,
                    ),
                  ),
                  const SizedBox(height: NeuroSpacing.xl),
                  Text(
                    'التحقق من رقم الهاتف',
                    style: theme.headlineMedium,
                  ),
                  const SizedBox(height: NeuroSpacing.sm),
                  Text(
                    'أدخل رقم هاتفك لاستلام رمز التحقق',
                    style: theme.bodyMedium?.copyWith(
                      color: NeuroColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NeuroSpacing.xxl),
                  AppInput(
                    label: 'رقم الهاتف',
                    hint: '05xxxxxxxx',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    enabled: !_codeSent,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'رقم الهاتف مطلوب';
                      if (v.length < 10) return 'رقم الهاتف غير صحيح';
                      return null;
                    },
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: NeuroSpacing.lg),
                    AppInput(
                      label: 'رمز التحقق',
                      hint: 'أدخل الرمز المكون من 6 أرقام',
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.pin_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'رمز التحقق مطلوب';
                        if (v.length < 6) return 'الرمز غير مكتمل';
                        return null;
                      },
                    ),
                  ],
                  if (authState.error != null) ...[
                    const SizedBox(height: NeuroSpacing.md),
                    AlertBanner(
                      severity: AlertSeverity.critical,
                      title: authState.error!,
                    ),
                  ],
                  const SizedBox(height: NeuroSpacing.xl),
                  if (!_codeSent)
                    AppButton(
                      label: 'إرسال رمز التحقق',
                      onPressed: _sendCode,
                      isLoading: authState.isLoading,
                    ),
                  if (_codeSent) ...[
                    AppButton(
                      label: 'التحقق من الرمز',
                      onPressed: _verifyCode,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: NeuroSpacing.md),
                    AppButton(
                      label: 'إعادة إرسال الرمز',
                      onPressed: _sendCode,
                      variant: ButtonVariant.ghost,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
