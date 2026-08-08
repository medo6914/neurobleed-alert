import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../../app/providers/app_providers.dart';

final userSettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/auth/me');
  return response.data is Map
      ? Map<String, dynamic>.from(response.data as Map)
      : {};
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = false;
  bool _biometricEnabled = false;
  bool _bluetoothEnabled = true;
  bool _locationEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final userAsync = ref.read(userSettingsProvider);
    final user = userAsync.valueOrNull;
    if (user != null) {
      final prefs = user['notification_preferences'];
      if (prefs is Map) {
        setState(() {
          _pushEnabled = prefs['push'] ?? true;
          _emailEnabled = prefs['email'] ?? false;
          _smsEnabled = prefs['sms'] ?? false;
        });
      }
      setState(() {
        _biometricEnabled = user['is_mfa_enabled'] ?? false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/v1/auth/me', data: {
        'notification_preferences': {
          'push': _pushEnabled,
          'email': _emailEnabled,
          'sms': _smsEnabled,
        },
      });
      ref.invalidate(userSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التفضيلات'),
            backgroundColor: NeuroColors.low,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحفظ: $e'),
            backgroundColor: NeuroColors.critical,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
          Text('الإشعارات', style: NeuroTypography.h3),
          const SizedBox(height: NeuroSpacing.md),
          _buildSwitchTile(
            Icons.notifications,
            'إشعارات الدفع',
            'استلام إشعارات فورية',
            _pushEnabled,
            (value) {
              setState(() => _pushEnabled = value);
              _savePreferences();
            },
          ),
          _buildSwitchTile(
            Icons.email,
            'إشعارات البريد الإلكتروني',
            'استلام تنبيقات عبر البريد',
            _emailEnabled,
            (value) {
              setState(() => _emailEnabled = value);
              _savePreferences();
            },
          ),
          _buildSwitchTile(
            Icons.sms,
            'رسائل SMS',
            'استلام رسائل نصية للطوارئ',
            _smsEnabled,
            (value) {
              setState(() => _smsEnabled = value);
              _savePreferences();
            },
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
          Text('الأمان', style: NeuroTypography.h3),
          const SizedBox(height: NeuroSpacing.md),
          _buildSwitchTile(
            Icons.fingerprint,
            'المصادقة البيومترية',
            'تسجيل الدخول بالبصمة',
            _biometricEnabled,
            (value) {
              setState(() => _biometricEnabled = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'تم تفعيل المصادقة البيومترية'
                        : 'تم تعطيل المصادقة البيومترية',
                  ),
                  backgroundColor: NeuroColors.low,
                ),
              );
            },
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
          Text('الجهاز', style: NeuroTypography.h3),
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
          Text('المظهر', style: NeuroTypography.h3),
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
            _showFontSizeDialog();
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
          Text('حول التطبيق', style: NeuroTypography.h3),
          const SizedBox(height: NeuroSpacing.md),
          _buildSettingsTile(Icons.info, 'معلومات التطبيق', () {
            _showAboutDialog();
          }),
          _buildSettingsTile(Icons.description, 'شروط الاستخدام', () {
            _showTermsDialog();
          }),
          _buildSettingsTile(Icons.privacy_tip, 'سياسة الخصوصية', () {
            _showPrivacyDialog();
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
      trailing:
          const Icon(Icons.chevron_right, color: NeuroColors.navInactive),
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
            child:
                Text('حسناً', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('تغيير كلمة المرور', style: NeuroTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الحالية',
                labelStyle: NeuroTypography.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeuroRadius.md),
                ),
              ),
            ),
            const SizedBox(height: NeuroSpacing.md),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                labelStyle: NeuroTypography.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeuroRadius.md),
                ),
              ),
            ),
            const SizedBox(height: NeuroSpacing.md),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                labelStyle: NeuroTypography.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(NeuroRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: TextStyle(color: NeuroColors.navInactive)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('كلمتا المرور غير متطابقتين'),
                    backgroundColor: NeuroColors.critical,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              try {
                final api = ref.read(apiClientProvider);
                await api.post('/v1/auth/change-password', data: {
                  'current_password': currentController.text,
                  'new_password': newController.text,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تغيير كلمة المرور بنجاح'),
                      backgroundColor: NeuroColors.low,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل: $e'),
                      backgroundColor: NeuroColors.critical,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeuroColors.primary,
              foregroundColor: NeuroColors.textSecondary,
            ),
            child: const Text('تغيير'),
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

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('حجم الخط', style: NeuroTypography.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('صغير', style: NeuroTypography.bodyMedium),
              value: 'small',
              groupValue: 'medium',
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تغيير حجم الخط')),
                );
              },
              activeColor: NeuroColors.primary,
            ),
            RadioListTile<String>(
              title: Text('متوسط', style: NeuroTypography.bodyMedium),
              value: 'medium',
              groupValue: 'medium',
              onChanged: (value) => Navigator.pop(context),
              activeColor: NeuroColors.primary,
            ),
            RadioListTile<String>(
              title: Text('كبير', style: NeuroTypography.bodyMedium),
              value: 'large',
              groupValue: 'medium',
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تغيير حجم الخط')),
                );
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
            const SizedBox(height: NeuroSpacing.md),
            Text(
              ' developed with ❤️ for brain health',
              style: NeuroTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('إغلاق', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('شروط الاستخدام', style: NeuroTypography.h3),
        content: SingleChildScrollView(
          child: Text(
            'شروط الاستخدام\n\n'
            '1. استخدام التطبيق على مسؤوليتك الخاصة\n'
            '2. لا يحل التطبيق استشارة الطبيب المختص\n'
            '3. بياناتك محمية وفقاً لسياسة الخصوصية\n'
            '4. يُحظر استخدام التطبيق لأغراض غير قانونية\n'
            '5. نحتفظ بحق تعليق الحساب في حالة الإساءة',
            style: NeuroTypography.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('إغلاق', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuroColors.bgCard,
        title: Text('سياسة الخصوصية', style: NeuroTypography.h3),
        content: SingleChildScrollView(
          child: Text(
            'سياسة الخصوصية\n\n'
            'نحترم خصوصيتك ونلتزم بحماية بياناتك:\n\n'
            '• نجمع فقط البيانات الضرورية لتشغيل التطبيق\n'
            '• لا نشارك بياناتك مع أطراف ثالثة\n'
            '• نستخدم تشفير البيانات أثناء النقل والتخزين\n'
            '• يمكنك حذف حسابك في أي وقت\n'
            '• نلتزم بقوانين حماية البيانات المعمول بها',
            style: NeuroTypography.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('إغلاق', style: TextStyle(color: NeuroColors.primary)),
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
          'أنت تستخدم أحدث إصدار من التطبيق (v1.0.0).',
          style: NeuroTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('حسناً', style: TextStyle(color: NeuroColors.primary)),
          ),
        ],
      ),
    );
  }
}
