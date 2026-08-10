import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../../app/providers/app_providers.dart';
import '../../core/auth/biometric_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNotificationsSection(),
                    const SizedBox(height: 16),
                    _buildSecuritySection(),
                    const SizedBox(height: 16),
                    _buildDeviceSection(),
                    const SizedBox(height: 16),
                    _buildAppearanceSection(isDark),
                    const SizedBox(height: 16),
                    _buildAboutSection(),
                    const SizedBox(height: 16),
                    _buildDangerZone(),
                    const SizedBox(height: 100),
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
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
            onPressed: () => context.go('/profile'),
          ),
          const Spacer(),
          const Text(
            'الإعدادات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSection(
      title: 'الإشعارات',
      children: [
        _buildSwitchTile(
          Icons.notifications_outlined,
          'إشعارات الدفع',
          'استلام إشعارات فورية',
          _pushEnabled,
          (value) => setState(() => _pushEnabled = value),
        ),
        _buildSwitchTile(
          Icons.email_outlined,
          'إشعارات البريد الإلكتروني',
          'استلام تنبيقات عبر البريد',
          _emailEnabled,
          (value) => setState(() => _emailEnabled = value),
        ),
        _buildSwitchTile(
          Icons.sms_outlined,
          'رسائل SMS',
          'استلام رسائل نصية للطوارئ',
          _smsEnabled,
          (value) => setState(() => _smsEnabled = value),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'الأمان',
      children: [
        _buildSwitchTile(
          Icons.fingerprint,
          'المصادقة البيومترية',
          'تسجيل الدخول بالبصمة',
          _biometricEnabled,
          (value) async {
            if (value) {
              final available = await biometricService.isAvailable();
              if (!available) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('المصادقة البيومترية غير متاحة على هذا الجهاز'),
                      backgroundColor: Color(0xFFFF3B30),
                    ),
                  );
                }
                return;
              }
              final authenticated = await biometricService.authenticate(
                reason: 'يرجى المصادقة لتفعيل البصمة',
              );
              if (authenticated) {
                setState(() => _biometricEnabled = true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تفعيل المصادقة البيومترية'),
                      backgroundColor: Color(0xFF34C759),
                    ),
                  );
                }
              }
            } else {
              setState(() => _biometricEnabled = false);
            }
          },
        ),
        _buildSettingsTile(Icons.lock_outlined, 'تغيير كلمة المرور', () {
          _showChangePasswordDialog();
        }),
        _buildSettingsTile(Icons.shield_outlined, 'التحقق من الهوية', () {}),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: const Text('تغيير كلمة المرور', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'كلمة المرور الحالية',
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF42A5F5)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('كلمتا المرور غير متطابقتين'),
                    backgroundColor: Color(0xFFFF3B30),
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
                      backgroundColor: Color(0xFF34C759),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل: $e'),
                      backgroundColor: const Color(0xFFFF3B30),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    return _buildSection(
      title: 'الجهاز',
      children: [
        _buildSwitchTile(
          Icons.bluetooth_outlined,
          'البلوتوث',
          'تفعيل الاتصال بالجهاز',
          _bluetoothEnabled,
          (value) => setState(() => _bluetoothEnabled = value),
        ),
        _buildSwitchTile(
          Icons.location_on_outlined,
          'خدمات الموقع',
          'مشاركة الموقع للطوارئ',
          _locationEnabled,
          (value) => setState(() => _locationEnabled = value),
        ),
        _buildSettingsTile(Icons.devices_outlined, 'الأجهزة المتصلة', () {}),
      ],
    );
  }

  Widget _buildAppearanceSection(bool isDark) {
    final fontSize = ref.watch(fontSizeProvider);
    return _buildSection(
      title: 'المظهر',
      children: [
        _buildSwitchTile(
          Icons.dark_mode_outlined,
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
        _buildSettingsTile(Icons.format_size, 'حجم الخط ($fontSize)', () {
          _showFontSizeDialog(fontSize);
        }),
      ],
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: const Text('اللغة', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('العربية', style: TextStyle(color: Colors.white)),
              value: 'ar',
              groupValue: 'ar',
              onChanged: (value) => Navigator.pop(context),
              activeColor: const Color(0xFF2196F3),
            ),
            RadioListTile<String>(
              title: const Text('English', style: TextStyle(color: Colors.white)),
              value: 'en',
              groupValue: 'ar',
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('اللغة الإنجليزية قيد التطوير'),
                    backgroundColor: Color(0xFF2196F3),
                  ),
                );
              },
              activeColor: const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(String currentSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: const Text('حجم الخط', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('صغير', style: TextStyle(color: Colors.white)),
              value: 'small',
              groupValue: currentSize,
              onChanged: (value) {
                ref.read(fontSizeProvider.notifier).setFontSize(value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF2196F3),
            ),
            RadioListTile<String>(
              title: const Text('متوسط', style: TextStyle(color: Colors.white)),
              value: 'medium',
              groupValue: currentSize,
              onChanged: (value) {
                ref.read(fontSizeProvider.notifier).setFontSize(value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF2196F3),
            ),
            RadioListTile<String>(
              title: const Text('كبير', style: TextStyle(color: Colors.white)),
              value: 'large',
              groupValue: currentSize,
              onChanged: (value) {
                ref.read(fontSizeProvider.notifier).setFontSize(value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'حول التطبيق',
      children: [
        _buildSettingsTile(Icons.info_outlined, 'معلومات التطبيق', () {}),
        _buildSettingsTile(Icons.description_outlined, 'شروط الاستخدام', () {}),
        _buildSettingsTile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', () {}),
        _buildSettingsTile(Icons.update, 'التحقق من التحديثات', () {}),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'منطقة الخطر',
            style: TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            Icons.delete_forever_outlined,
            'حذف البيانات',
            () {},
            color: const Color(0xFFFF3B30),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F35), Color(0xFF0D1220)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF8E8E93), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color ?? const Color(0xFF8E8E93),
            ),
          ],
        ),
      ),
    );
  }
}
