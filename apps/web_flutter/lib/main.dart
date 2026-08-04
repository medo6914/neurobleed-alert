import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeuroBleedWebApp());
}

class NeuroBleedWebApp extends StatelessWidget {
  const NeuroBleedWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NeuroBleed Alert - Web Dashboard',
      debugShowCheckedModeBanner: false,
      theme: _buildDarkTheme(),
      themeMode: ThemeMode.dark,
      locale: const Locale('en', 'US'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: AppRouter(AuthGuard()).router,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: NeuroColors.primary,
      brightness: Brightness.dark,
      textTheme: NeuroTypography.textTheme,
      scaffoldBackgroundColor: NeuroColors.backgroundDark,
    );
  }
}
