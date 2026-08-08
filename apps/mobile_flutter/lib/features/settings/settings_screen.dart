import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _locationEnabled = true;
  bool _bluetoothEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

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
                    _buildAppearanceSection(isDark),
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
            (value) => _showComingSoonDialog('إشعارات البريد الإلكتروني'),
          ),
          _buildSwitchTile(
            Icons.sms,
            'رسائل SMS',
            'استلام رسائل نصية للطوارئ',
            false,
            (value) => _showComingSoonDialog('رسائل SMS'),
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
            (value) => _showComingSoonDialog('المصادقة البيومترية'),
          ),
          _buildSettingsTile(Icons.lock, 'تغيير كلمة المرور', () {
            _showChangePasswordDialog();
          }),
          _buildSettingsTile(Icons.shield, 'التحقق من الهوية', () {
            _showComingSoonDialog('التحقق من الهوية');
          }),
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
            _bluetoothEnabled,
            (value) => setState(() => _bluetoothEnabled = value),
          ),
          _buildSwitchTile(
            Icons.location_on,
            'خدمات الموقع',
            'مشاركة الموقع للطوارئ',
            _locationEnabled,
            (value) => setState(() => _locationEnabled = value),
          ),
          _buildSettingsTile(Icons.devices_other, 'الأجهزة المتصلة', () {
            context.go('/devices');
          }),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(bool isDark) {
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
            isDark,
            (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
            },
          ),
          _buildSettingsTile(Icons.language, 'اللغة', () {
            _showLanguageDialog();
          }),
          _buildSettingsTile(Icons.format_size, 'حجم الخط', () {
            _showComingSoonDialog('حجم الخط');
          }),
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
          _buildSettingsTile(Icons.info, 'معلومات التطبيق', () {
            _showAboutDialog();
          }),
          _buildSettingsTile(Icons.description, 'شروط الاستخدام', () {
            _showComingSoonDialog('شروط الاستخدام');
          }),
          _buildSettingsTile(Icons.privacy_tip, 'سياسة الخصوصية', () {
            _showComingSoonDialog('سياسة الخصوصية');
          }),
          _buildSettingsTile(Icons.update, 'التحقق من التحديثات', () {
            _showUpdateDialog();
          }),
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

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: NeuroColors.navInactive),
      title: Text(title, style: NeuroTypography.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: NeuroColors.navInactive),
      onTap: onTap,
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('قريباً', style: NeuroTypography.h3),
        content: Text(
          'ميزة "$feature" قيد التطوير وستكون متاحة قريباً.',
          style: NeuroTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('تغيير كلمة المرور', style: NeuroTypography.h3),
        content: Text(
          'سيتم إرسال رابط تغيير كلمة المرور إلى بريدك الإلكتروني.',
          style: NeuroTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: NeuroColors.navInactive)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال رابط تغيير كلمة المرور')),
              );
            },
            child: Text('إرسال', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('اللغة', style: NeuroTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('العربية', style: NeuroTypography.bodyMedium),
              value: 'ar',
              groupValue: 'ar',
              onChanged: (value) => Navigator.pop(context),
              activeColor: NeuroColors.primary,
            ),
            RadioListTile<String>(
              title: Text('English', style: NeuroTypography.bodyMedium),
              value: 'en',
              groupValue: 'ar',
              onChanged: (value) {
                Navigator.pop(context);
                _showComingSoonDialog('اللغة الإنجليزية');
              },
              activeColor: NeuroColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('معلومات التطبيق', style: NeuroTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NeuroBleed Alert', style: NeuroTypography.h2),
            const SizedBox(height: NeuroSpacing.sm),
            Text('الإصدار: 1.0.0', style: NeuroTypography.bodyMedium),
            const SizedBox(height: NeuroSpacing.md),
            Text(
              'نظام مراقبة الدماغ الذكي للكشف المبكر عن نزيف الدماغ',
              style: NeuroTypography.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('التحقق من التحديثات', style: NeuroTypography.h3),
        content: Text(
          'أنت تستخدم أحدث إصدار من التطبيق.',
          style: NeuroTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }
}
