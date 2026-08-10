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
    final locale = ref.watch(localeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, t),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNotificationsSection(t),
                    const SizedBox(height: 16),
                    _buildSecuritySection(t),
                    const SizedBox(height: 16),
                    _buildDeviceSection(t),
                    const SizedBox(height: 16),
                    _buildAppearanceSection(isDark, locale, fontSize, t),
                    const SizedBox(height: 16),
                    _buildAboutSection(t),
                    const SizedBox(height: 16),
                    _buildDangerZone(t),
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

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
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
          Text(
            t.t('settings'),
            style: const TextStyle(
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

  Widget _buildNotificationsSection(AppLocalizations t) {
    return _buildSection(
      title: t.t('section_notifications'),
      children: [
        _buildSwitchTile(
          Icons.notifications_outlined,
          t.t('push_notifications'),
          t.t('push_notifications_desc'),
          _pushEnabled,
          (value) => setState(() => _pushEnabled = value),
        ),
        _buildSwitchTile(
          Icons.email_outlined,
          t.t('email_notifications'),
          t.t('email_notifications_desc'),
          _emailEnabled,
          (value) => setState(() => _emailEnabled = value),
        ),
        _buildSwitchTile(
          Icons.sms_outlined,
          t.t('sms_messages'),
          t.t('sms_messages_desc'),
          _smsEnabled,
          (value) => setState(() => _smsEnabled = value),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(AppLocalizations t) {
    return _buildSection(
      title: t.t('section_security'),
      children: [
        _buildSwitchTile(
          Icons.fingerprint,
          t.t('biometric_auth'),
          t.t('biometric_auth_desc'),
          _biometricEnabled,
          (value) async {
            if (value) {
              final available = await biometricService.isAvailable();
              if (!available) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.t('biometric_not_available')),
                      backgroundColor: const Color(0xFFFF3B30),
                    ),
                  );
                }
                return;
              }
              final authenticated = await biometricService.authenticate(
                reason: t.t('biometric_auth_reason'),
              );
              if (authenticated) {
                setState(() => _biometricEnabled = true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.t('biometric_enabled')),
                      backgroundColor: const Color(0xFF34C759),
                    ),
                  );
                }
              }
            } else {
              setState(() => _biometricEnabled = false);
            }
          },
        ),
        _buildSettingsTile(Icons.lock_outlined, t.t('change_password'), () {
          _showChangePasswordDialog(t);
        }),
        _buildSettingsTile(Icons.shield_outlined, t.t('verify_identity'), () {}),
      ],
    );
  }

  void _showChangePasswordDialog(AppLocalizations t) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('change_password'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: t.t('current_password'),
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
                labelText: t.t('new_password'),
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
                labelText: t.t('confirm_password'),
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
            child: Text(t.t('cancel'), style: const TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.t('passwords_not_match')),
                    backgroundColor: const Color(0xFFFF3B30),
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
                    SnackBar(
                      content: Text(t.t('password_changed_success')),
                      backgroundColor: const Color(0xFF34C759),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$e'),
                      backgroundColor: const Color(0xFFFF3B30),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
            child: Text(t.t('change')),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection(AppLocalizations t) {
    return _buildSection(
      title: t.t('section_device'),
      children: [
        _buildSwitchTile(
          Icons.bluetooth_outlined,
          t.t('bluetooth'),
          t.t('bluetooth_desc'),
          _bluetoothEnabled,
          (value) => setState(() => _bluetoothEnabled = value),
        ),
        _buildSwitchTile(
          Icons.location_on_outlined,
          t.t('location_services'),
          t.t('location_services_desc'),
          _locationEnabled,
          (value) => setState(() => _locationEnabled = value),
        ),
        _buildSettingsTile(Icons.devices_outlined, t.t('connected_devices'), () {
          context.go('/devices');
        }),
      ],
    );
  }

  Widget _buildAppearanceSection(bool isDark, Locale locale, String fontSize, AppLocalizations t) {
    return _buildSection(
      title: t.t('section_appearance'),
      children: [
        _buildSwitchTile(
          Icons.dark_mode_outlined,
          t.t('darkMode'),
          t.t('dark_mode_desc'),
          isDark,
          (value) {
            ref.read(themeModeProvider.notifier).setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
          },
        ),
        _buildSettingsTile(Icons.language, '${t.t('language')} (${locale.languageCode == 'ar' ? t.t('language_arabic') : t.t('language_english')})', () {
          _showLanguageDialog(locale, t);
        }),
        _buildSettingsTile(Icons.format_size, '${t.t('font_size')} ($fontSize)', () {
          _showFontSizeDialog(fontSize, t);
        }),
      ],
    );
  }

  void _showLanguageDialog(Locale currentLocale, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('language'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(t.t('language_arabic'), style: const TextStyle(color: Colors.white)),
              value: 'ar',
              groupValue: currentLocale.languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setArabic();
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF2196F3),
            ),
            RadioListTile<String>(
              title: Text(t.t('language_english'), style: const TextStyle(color: Colors.white)),
              value: 'en',
              groupValue: currentLocale.languageCode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setEnglish();
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF2196F3),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(String currentSize, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('font_size'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(t.t('font_size_small'), style: const TextStyle(color: Colors.white)),
              value: 'small',
              groupValue: currentSize,
              onChanged: (value) {
                ref.read(fontSizeProvider.notifier).setFontSize(value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF2196F3),
            ),
            RadioListTile<String>(
              title: Text(t.t('font_size_medium'), style: const TextStyle(color: Colors.white)),
              value: 'medium',
              groupValue: currentSize,
              onChanged: (value) {
                ref.read(fontSizeProvider.notifier).setFontSize(value!);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFF2196F3),
            ),
            RadioListTile<String>(
              title: Text(t.t('font_size_large'), style: const TextStyle(color: Colors.white)),
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

  Widget _buildAboutSection(AppLocalizations t) {
    return _buildSection(
      title: t.t('section_about'),
      children: [
        _buildSettingsTile(Icons.info_outlined, t.t('app_info'), () {
          showAboutDialog(
            context: context,
            applicationName: 'NeuroBleed Alert',
            applicationVersion: '1.0.0',
            applicationIcon: const Icon(Icons.psychology, color: Color(0xFF2196F3), size: 48),
            children: [
              Text(t.t('app_tagline')),
            ],
          );
        }),
        _buildSettingsTile(Icons.description_outlined, t.t('terms_of_use'), () {
          _showTermsDialog(t);
        }),
        _buildSettingsTile(Icons.privacy_tip_outlined, t.t('privacy_policy'), () {
          _showPrivacyDialog(t);
        }),
        _buildSettingsTile(Icons.update, t.t('check_updates'), () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.t('loading')),
              backgroundColor: const Color(0xFF2196F3),
            ),
          );
        }),
      ],
    );
  }

  void _showTermsDialog(AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('terms_of_use'), style: const TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            'NeuroBleed Alert - Terms of Use\n\n'
            '1. This application is designed to provide brain health monitoring alerts.\n\n'
            '2. The device should be used as directed and is not a replacement for professional medical advice.\n\n'
            '3. Always consult a healthcare provider for medical decisions.\n\n'
            '4. Emergency alerts should be taken seriously and appropriate action should be taken.\n\n'
            '5. Data collected is used for health monitoring purposes only.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.t('confirm'), style: const TextStyle(color: Color(0xFF2196F3))),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('privacy_policy'), style: const TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            'NeuroBleed Alert - Privacy Policy\n\n'
            'We collect health monitoring data to provide you with brain health alerts.\n\n'
            'Your data is encrypted and stored securely.\n\n'
            'We do not share your personal health data with third parties without your consent.\n\n'
            'You can request data deletion at any time from the settings.\n\n'
            'Emergency location sharing is only activated when you trigger an emergency alert.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.t('confirm'), style: const TextStyle(color: Color(0xFF2196F3))),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(AppLocalizations t) {
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
          Text(
            t.t('danger_zone'),
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            Icons.delete_forever_outlined,
            t.t('delete_data'),
            () {
              _showDeleteDataDialog(t);
            },
            color: const Color(0xFFFF3B30),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog(AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F35),
        title: Text(t.t('delete_data'), style: const TextStyle(color: const Color(0xFFFF3B30))),
        content: Text(
          '${t.t('delete_data')}?',
          style: const TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.t('cancel'), style: const TextStyle(color: Color(0xFF8E8E93))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.t('loading')),
                  backgroundColor: const Color(0xFFFF3B30),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            child: Text(t.t('delete'), style: const TextStyle(color: Colors.white)),
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
