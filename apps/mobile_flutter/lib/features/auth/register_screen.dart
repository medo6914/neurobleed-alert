import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import '../../core/auth/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _role = 'doctor';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            role: _role,
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
        title: const Text('إنشاء حساب جديد'),
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
                  AppInput(
                    label: 'الاسم الكامل',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'الاسم مطلوب';
                      if (v.length < 2) return 'الاسم قصير جداً';
                      return null;
                    },
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  AppInput(
                    label: 'البريد الإلكتروني',
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                      if (v.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                      if (!RegExp(r'[A-Z]').hasMatch(v)) {
                        return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(v)) {
                        return 'يجب أن تحتوي على رقم واحد على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  AppInput(
                    label: 'تأكيد كلمة المرور',
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
                  const SizedBox(height: NeuroSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: InputDecoration(
                      labelText: 'الدور',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: NeuroColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NeuroRadius.md),
                        borderSide:
                            const BorderSide(color: NeuroColors.chartGrid),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(NeuroRadius.md),
                        borderSide:
                            const BorderSide(color: NeuroColors.chartGrid),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'doctor', child: Text('طبيب')),
                      DropdownMenuItem(value: 'nurse', child: Text('ممرض')),
                      DropdownMenuItem(value: 'technician', child: Text('فني')),
                      DropdownMenuItem(value: 'admin', child: Text('مدير')),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'doctor'),
                  ),
                  if (authState.error != null) ...[
                    const SizedBox(height: NeuroSpacing.md),
                    AlertBanner(
                      severity: AlertSeverity.critical,
                      title: authState.error!,
                    ),
                  ],
                  const SizedBox(height: NeuroSpacing.xl),
                  AppButton(
                    label: 'إنشاء حساب',
                    onPressed: _onRegister,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: NeuroSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('لديك حساب؟ ',
                          style: theme.bodyMedium?.copyWith(
                              color: NeuroColors.textSecondary)),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('تسجيل دخول'),
                      ),
                    ],
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
