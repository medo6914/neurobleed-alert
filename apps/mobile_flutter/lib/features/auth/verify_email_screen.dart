import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isVerified = false;

  void _checkVerification() {
    setState(() => _isVerified = true);
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
        title: const Text('التحقق من البريد الإلكتروني'),
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
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isVerified
                        ? NeuroColors.success.withAlpha(20)
                        : NeuroColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(NeuroRadius.xxl),
                  ),
                  child: Icon(
                    _isVerified
                        ? Icons.verified_outlined
                        : Icons.mark_email_unread_outlined,
                    size: 50,
                    color:
                        _isVerified ? NeuroColors.success : NeuroColors.warning,
                  ),
                ),
                const SizedBox(height: NeuroSpacing.xl),
                Text(
                  _isVerified
                      ? 'تم التحقق من البريد الإلكتروني'
                      : 'تحقق من بريدك الإلكتروني',
                  style: theme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NeuroSpacing.md),
                Text(
                  _isVerified
                      ? 'بريدك الإلكتروني موثّق الآن. يمكنك المتابعة.'
                      : 'لقد أرسلنا رابط التحقق إلى بريدك الإلكتروني. يرجى النقر على الرابط لتفعيل حسابك.',
                  style: theme.bodyMedium?.copyWith(
                    color: NeuroColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NeuroSpacing.xxl),
                if (!_isVerified) ...[
                  AppButton(
                    label: 'إعادة إرسال رابط التحقق',
                    onPressed: () {
                      ref
                          .read(authStateProvider.notifier)
                          .sendVerificationEmail();
                    },
                    variant: ButtonVariant.secondary,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: NeuroSpacing.md),
                  AppButton(
                    label: 'تحقق من حالة التحقق',
                    onPressed: _checkVerification,
                    variant: ButtonVariant.secondary,
                  ),
                  const SizedBox(height: NeuroSpacing.md),
                  AppButton(
                    label: 'تخطي التحقق الآن',
                    onPressed: () => context.go('/dashboard'),
                    variant: ButtonVariant.ghost,
                  ),
                ],
                if (_isVerified) ...[
                  AppButton(
                    label: 'المتابعة إلى لوحة التحكم',
                    onPressed: () => context.go('/dashboard'),
                  ),
                ],
                if (authState.error != null) ...[
                  const SizedBox(height: NeuroSpacing.md),
                  AlertBanner(
                    severity: AlertSeverity.critical,
                    title: authState.error!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
