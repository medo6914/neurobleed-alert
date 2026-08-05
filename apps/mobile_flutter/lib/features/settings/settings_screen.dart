import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _biometricEnabled = false;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuroColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(NeuroSpacing.lg),
                child: Column(
                  children: [
                    _buildNotificationsSection(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildSecuritySection(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildDeviceSection(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildAppearanceSection(),
                    const SizedBox(height: NeuroSpacing.xl),
                    _buildAboutSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        NeuroSpacing.lg,
        MediaQuery.of(context).padding.top + NeuroSpacing.sm,
        NeuroSpacing.lg,
        NeuroSpacing.sm,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NeuroColors.headerGradTop, NeuroColors.headerGradBottom],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: NeuroColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'الإعدادات',
              style: NeuroTypography.h1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإشعارات',
            style: NeuroTypography.h3,
          ),
          const SizedBox(height: NeuroSpacing.md),
          _buildSwitchTile(
            Icons.notifications,
            'إشعارات الدفع',
            'استلام إشعارات فورية',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSwitchTile(
            Icons.email,
            'إشعارات البريد الإلكتروني',
            'استلام تنبيقات عبر البريد',
            false,
            (value) {},
          ),
          _buildSwitchTile(
            Icons.sms,
            'رسائل SMS',
            'استلام رسائل نصية للطوارئ',
            false,
            (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأمان',
            style: NeuroTypography.h3,
          ),
          const SizedBox(height: NeuroSpacing.md),
          _buildSwitchTile(
            Icons.fingerprint,
            'المصادقة البيومترية',
            'تسجيل الدخول بالبصمة',
            _biometricEnabled,
            (value) => setState(() => _biometricEnabled = value),
          ),
          _buildSettingsTile(Icons.lock, 'تغيير كلمة المرور'),
          _buildSettingsTile(Icons.shield, 'التحقق من الهوية'),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الجهاز',
            style: NeuroTypography.h3,
          ),
          const SizedBox(height: NeuroSpacing.md),
          _buildSwitchTile(
            Icons.bluetooth,
            'البلوتوث',
            'تفعيل الاتصال بالجهاز',
            true,
            (value) {},
          ),
          _buildSwitchTile(
            Icons.location_on,
            'خدمات الموقع',
            'مشاركة الموقع للطوارئ',
            _locationEnabled,
            (value) => setState(() => _locationEnabled = value),
          ),
          _buildSettingsTile(Icons.devices_other, 'الأجهزة المتصلة'),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المظهر',
            style: NeuroTypography.h3,
          ),
          const SizedBox(height: NeuroSpacing.md),
          _buildSwitchTile(
            Icons.dark_mode,
            'الوضع الداكن',
            'تفعيل المظهر الداكن',
            _darkModeEnabled,
            (value) => setState(() => _darkModeEnabled = value),
          ),
          _buildSettingsTile(Icons.language, 'اللغة'),
          _buildSettingsTile(Icons.format_size, 'حجم الخط'),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(NeuroSpacing.lg),
      decoration: BoxDecoration(
        color: NeuroColors.bgCard,
        borderRadius: BorderRadius.circular(NeuroRadius.card),
        border:
            Border.all(color: NeuroColors.textPrimary.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حول التطبيق',
            style: NeuroTypography.h3,
          ),
          const SizedBox(height: NeuroSpacing.md),
          _buildSettingsTile(Icons.info, 'معلومات التطبيق'),
          _buildSettingsTile(Icons.description, 'شروط الاستخدام'),
          _buildSettingsTile(Icons.privacy_tip, 'سياسة الخصوصية'),
          _buildSettingsTile(Icons.update, 'التحقق من التحديثات'),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: NeuroColors.navInactive),
      title: Text(title, style: NeuroTypography.bodyMedium),
      subtitle: Text(subtitle, style: NeuroTypography.caption),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: NeuroColors.primary,
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: NeuroColors.navInactive),
      title: Text(title, style: NeuroTypography.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: NeuroColors.navInactive),
      onTap: () {},
    );
  }
}
