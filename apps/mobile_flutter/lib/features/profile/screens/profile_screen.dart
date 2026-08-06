import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/entities/user.dart';
import '../../../core/auth/auth_provider.dart' show authStateProvider;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isEditing = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
      ),
      body: user == null
          ? const Center(child: AppLoading())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(NeuroSpacing.lg),
              child: Column(
                children: [
                  _buildHeader(user),
                  const SizedBox(height: NeuroSpacing.xl),
                  _buildInfoCard(user),
                  const SizedBox(height: NeuroSpacing.xl),
                  _buildEditCard(user),
                  const SizedBox(height: NeuroSpacing.xl),
                  _buildDetails(user),
                  const SizedBox(height: NeuroSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NeuroSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [NeuroColors.headerGradTop, NeuroColors.headerGradBottom],
        ),
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        boxShadow: const [NeuroShadows.card],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: NeuroColors.primary.withValues(alpha: 0.35),
                child: Icon(
                  Icons.person,
                  size: 44,
                  color: NeuroColors.textPrimary,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NeuroColors.success,
                    border: Border.all(color: NeuroColors.bgCard, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NeuroSpacing.md),
          Text(
            user.displayName ?? 'مستخدم',
            style: NeuroTypography.h2,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: NeuroTypography.caption,
          ),
          const SizedBox(height: NeuroSpacing.md),
          Text(
            user.email,
            style: NeuroTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(User user) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(NeuroSpacing.lg),
        child: Column(
          children: [
            _infoRow(Icons.email_outlined, 'البريد الإلكتروني', user.email),
            const Divider(color: NeuroColors.bgCard),
            _infoRow(Icons.phone_outlined, 'رقم الهاتف', user.phone ?? '—'),
            const Divider(color: NeuroColors.bgCard),
            _infoRow(
              Icons.badge_outlined,
              'المعرف',
              user.id,
              monospace: true,
            ),
            const Divider(color: NeuroColors.bgCard),
            _infoRow(
              Icons.calendar_today_outlined,
              'تاريخ التسجيل',
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool monospace = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: NeuroColors.textBody),
        const SizedBox(width: NeuroSpacing.md),
        Text(label, style: NeuroTypography.body),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: NeuroTypography.bodyMedium.copyWith(
              color: NeuroColors.textPrimary,
              fontFamily: monospace ? 'monospace' : null,
              fontSize: monospace ? 11 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEditCard(User user) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(NeuroSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تعديل البيانات', style: NeuroTypography.h2),
            const SizedBox(height: NeuroSpacing.lg),
            AppInput(
              label: 'الاسم الكامل',
              controller: _nameController,
              enabled: _isEditing,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: NeuroSpacing.md),
            AppInput(
              label: 'رقم الهاتف',
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: NeuroSpacing.lg),
            if (!_isEditing)
              AppButton(
                label: 'تعديل البيانات',
                icon: Icons.edit_outlined,
                variant: ButtonVariant.secondary,
                onPressed: () => setState(() => _isEditing = true),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _saving ? 'جاري الحفظ...' : 'حفظ',
                      icon: Icons.check,
                      isLoading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                  const SizedBox(width: NeuroSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'إلغاء',
                      variant: ButtonVariant.secondary,
                      onPressed: () => setState(() => _isEditing = false),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(authStateProvider.notifier).updateProfile({
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
    setState(() {
      _saving = false;
      _isEditing = false;
    });
  }

  Widget _buildDetails(User user) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(NeuroSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('معلومات إضافية', style: NeuroTypography.h2),
            const SizedBox(height: NeuroSpacing.md),
            _infoRow(
              Icons.verified_user_outlined,
              'حالة الحساب',
              user.isActive ? 'نشط' : 'موقوف',
            ),
            const Divider(color: NeuroColors.bgCard),
            _infoRow(
              Icons.account_balance_outlined,
              'المستشفى',
              user.hospitalId ?? 'غير محدد',
            ),
            const Divider(color: NeuroColors.bgCard),
            _infoRow(
              Icons.login_outlined,
              'طريقة الدخول',
              user.authProvider == AuthProvider.google
                  ? 'Google'
                  : user.authProvider == AuthProvider.phone
                      ? 'رقم الهاتف'
                      : 'بريد إلكتروني',
            ),
          ],
        ),
      ),
    );
  }
}
