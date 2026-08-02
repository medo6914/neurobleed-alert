import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../../app/providers/app_providers.dart';
import '../../core/auth/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate(L10n.settings) ?? 'Settings'),
        backgroundColor: const Color(0xFF0C1427),
      ),
      body: ListView(
        padding: const EdgeInsets.all(NeuroSpacing.lg),
        children: [
          // Profile card (reference: bg #0c1529)
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
            padding: const EdgeInsets.all(NeuroSpacing.xl),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1529),
              borderRadius: BorderRadius.circular(NeuroRadius.card),
              boxShadow: const [NeuroShadows.card],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor:
                          NeuroColors.primary.withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.person,
                        size: 34,
                        color: NeuroColors.textPrimary,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1ACB58),
                          border: Border.all(
                            color: const Color(0xFF0C1529),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: NeuroSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دكتور',
                        style: NeuroTypography.h3.copyWith(
                          color: NeuroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المستشفى الجامعي',
                        style: NeuroTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: NeuroColors.textBody,
                  ),
                  onPressed: () => context.push('/profile'),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: NeuroSpacing.xl),
          // Preferences section
          Text('التفضيلات', style: NeuroTypography.h2),
          const SizedBox(height: NeuroSpacing.md),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'الإشعارات',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'الوضع الداكن',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.language_outlined,
            label: 'اللغة',
            subtitle: locale.languageCode == 'ar' ? 'العربية' : 'English',
            onTap: () {
              final newLocale =
                  locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
              ref.read(localeProvider.notifier).setLocale(newLocale);
            },
          ),
          const SizedBox(height: NeuroSpacing.xl),
          // Account section
          Text('الحساب', style: NeuroTypography.h2),
          const SizedBox(height: NeuroSpacing.md),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'تغيير كلمة المرور',
            onTap: () => context.push('/forgot-password'),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            label: 'الخصوصية والأمان',
            onTap: () {},
          ),
          const SizedBox(height: NeuroSpacing.xl),
          // About section
          Text('حول', style: NeuroTypography.h2),
          const SizedBox(height: NeuroSpacing.md),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'الإصدار',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'التراخيص',
            onTap: () => showLicensePage(context: context),
          ),
          const SizedBox(height: NeuroSpacing.xl),
          // Logout
          AppButton(
            label: 'تسجيل الخروج',
            variant: ButtonVariant.danger,
            icon: Icons.logout,
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(authStateProvider.notifier).logout();
                        context.go('/login');
                      },
                      child: const Text('تأكيد'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: NeuroSpacing.xxl),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: NeuroSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFF131E3A),
        borderRadius: BorderRadius.circular(NeuroRadius.md),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: NeuroColors.textBody, size: 22),
        title: Text(
          label,
          style: NeuroTypography.bodyMedium.copyWith(
            color: NeuroColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: NeuroTypography.caption,
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: NeuroColors.navInactive,
                  )
                : null),
      ),
    );
  }
}
