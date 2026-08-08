import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String identifier;

  const OtpScreen({super.key, required this.identifier});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _canResend = true;
        }
      });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onVerify() {
    final code = _codeController.text.trim();
    if (code.length >= 6) {
      ref.read(authStateProvider.notifier).verifyOtp(
            widget.identifier,
            code,
          );
    }
  }

  void _onResend() {
    if (_canResend) {
      ref.read(authStateProvider.notifier).sendOtp(widget.identifier);
      _startResendTimer();
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
        title: const Text('التحقق'),
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: NeuroColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(NeuroRadius.xxl),
                  ),
                  child: const Icon(
                    Icons.pin_outlined,
                    size: 40,
                    color: NeuroColors.primary,
                  ),
                ),
                const SizedBox(height: NeuroSpacing.xl),
                Text(
                  'أدخل رمز التحقق',
                  style: theme.headlineMedium,
                ),
                const SizedBox(height: NeuroSpacing.sm),
                Text(
                  'تم إرسال رمز التحقق إلى ${widget.identifier}',
                  style: theme.bodyMedium?.copyWith(
                    color: NeuroColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NeuroSpacing.xxl),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: theme.displaySmall?.copyWith(
                      letterSpacing: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: NeuroColors.background,
                      hintText: '------',
                      hintStyle: theme.displaySmall?.copyWith(
                        color: NeuroColors.chartGrid,
                        letterSpacing: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NeuroRadius.md),
                        borderSide:
                            const BorderSide(color: NeuroColors.chartGrid),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NeuroRadius.md),
                        borderSide: const BorderSide(
                            color: NeuroColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: NeuroSpacing.lg,
                        vertical: NeuroSpacing.lg,
                      ),
                    ),
                    onChanged: (v) {
                      if (v.length == 6) _onVerify();
                    },
                  ),
                ),
                const SizedBox(height: NeuroSpacing.lg),
                if (authState.error != null)
                  AlertBanner(
                    severity: AlertSeverity.critical,
                    title: authState.error!,
                  ),
                const SizedBox(height: NeuroSpacing.xl),
                AppButton(
                  label: 'تحقق',
                  onPressed: _onVerify,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: NeuroSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _canResend ? _onResend : null,
                      child: Text(
                        _canResend
                            ? 'إعادة إرسال الرمز'
                            : 'إعادة الإرسال بعد $_resendSeconds ثانية',
                        style: theme.bodyMedium?.copyWith(
                          color: _canResend
                              ? NeuroColors.primary
                              : NeuroColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
