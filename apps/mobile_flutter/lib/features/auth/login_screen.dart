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
  bool _rememberMe = true;

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
            rememberMe: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

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
              Color(0xFF020C23),
              Color(0xFF051B38),
              NeuroColors.bgPrimary,
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NeuroSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: NeuroSpacing.lg),
                  _buildTitle(),
                  const SizedBox(height: NeuroSpacing.xxl),
                  _buildLoginForm(authState),
                  const SizedBox(height: NeuroSpacing.xl),
                  _buildRegisterPrompt(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFAEE4FF).withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Icon(
            Icons.psychology_outlined,
            size: 50,
            color: Color(0xFFAEE4FF),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Neuro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'Bleed',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: NeuroColors.critical,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NeuroSpacing.xs),
        Text(
          'نظام تقييم خطر النزيف الدماغي',
          style: NeuroTypography.body?.copyWith(
            color: NeuroColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthState authState) {
    return AppCard(
      padding: const EdgeInsets.all(NeuroSpacing.xxl),
      borderRadius: BorderRadius.circular(NeuroRadius.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تسجيل الدخول',
              style: NeuroTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NeuroSpacing.xl),
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
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                  activeColor: NeuroColors.primary,
                ),
                const SizedBox(width: NeuroSpacing.xs),
                Text('تذكرني', style: NeuroTypography.bodyMedium),
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: NeuroSpacing.md),
                  child: Text('أو', style: NeuroTypography.caption),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: NeuroSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBiometricButton(Icons.fingerprint, 'بصمة'),
                const SizedBox(width: NeuroSpacing.lg),
                _buildBiometricButton(Icons.face, 'وجه'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: NeuroColors.bgInput,
            borderRadius: BorderRadius.circular(NeuroRadius.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: NeuroColors.textSecondary, size: 30),
        ),
        const SizedBox(height: NeuroSpacing.xs),
        Text(label, style: NeuroTypography.caption),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('ليس لديك حساب؟ ', style: NeuroTypography.body),
        TextButton(
          onPressed: () => context.push('/register'),
          child: const Text('إنشاء حساب'),
        ),
      ],
    );
  }
}
