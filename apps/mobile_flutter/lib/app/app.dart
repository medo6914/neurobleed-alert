import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:core/core.dart';
import 'providers/app_providers.dart';

class NeuroBleedApp extends ConsumerWidget {
  const NeuroBleedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[APP] NeuroBleedApp.build');
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    debugPrint('[APP] router + theme ready, themeMode=$themeMode');

    return MaterialApp.router(
      title: 'NeuroBleed Alert',
      debugShowCheckedModeBanner: false,
      theme: NeuroThemeData.light(fontFamily: NeuroTypography.fontFamily),
      darkTheme: NeuroThemeData.dark(fontFamily: NeuroTypography.fontFamily),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
