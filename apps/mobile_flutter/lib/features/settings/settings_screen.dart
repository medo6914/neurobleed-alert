import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import '../../app/providers/app_providers.dart';
import '../../core/auth/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate(L10n.settings) ?? 'Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.translate(L10n.darkMode) ?? 'Dark Mode'),
            subtitle: Text(
              themeMode == ThemeMode.dark ? 'مفعل' : 'غير مفعل',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.translate(L10n.language) ?? 'Language'),
            subtitle: Text(
              locale.languageCode == 'ar' ? 'العربية' : 'English',
            ),
            trailing: SegmentedButton<Locale>(
              segments: const [
                ButtonSegment(
                  value: Locale('en', 'US'),
                  label: Text('EN'),
                ),
                ButtonSegment(
                  value: Locale('ar', 'SA'),
                  label: Text('AR'),
                ),
              ],
              selected: {locale},
              onSelectionChanged: (selected) {
                ref.read(localeProvider.notifier).setLocale(selected.first);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.translate(L10n.about) ?? 'About'),
            subtitle: Text(
              '${l10n.translate(L10n.version) ?? 'Version'} 1.0.0',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: NeuroColors.error),
            title: Text(
              l10n.translate(L10n.logout) ?? 'Logout',
              style: const TextStyle(color: NeuroColors.error),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.translate(L10n.logout) ?? 'Logout'),
                  content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.translate(L10n.cancel) ?? 'Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(authStateProvider.notifier).logout();
                        context.go('/login');
                      },
                      child: Text(l10n.translate(L10n.confirm) ?? 'Confirm'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
