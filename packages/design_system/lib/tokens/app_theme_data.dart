import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_shadows.dart';
import 'app_radius.dart';

class NeuroThemeData {
  NeuroThemeData._();

  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surfaceColor,
    required Color appBarBg,
    required Color appBarFg,
    required Color navBg,
    required Color navActive,
    required Color navInactive,
    required Color primaryClr,
    required Color primaryContainerClr,
    required Color onPrimaryClr,
    required Color secondaryClr,
    required Color errorClr,
    required Color onSurfaceClr,
    required Color inputFill,
    required Color cardBg,
    required Color dividerClr,
    required Color hintClr,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryClr,
      onPrimary: onPrimaryClr,
      primaryContainer: primaryContainerClr,
      secondary: secondaryClr,
      onSecondary: onPrimaryClr,
      error: errorClr,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: onSurfaceClr,
    );

    final textTheme = NeuroTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: onSurfaceClr,
        displayColor: NeuroColors.textPrimary,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 2,
        shadowColor: NeuroShadows.card.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: NeuroColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: NeuroColors.textBody),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: navActive,
        unselectedItemColor: navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryClr,
        foregroundColor: onPrimaryClr,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: textTheme.bodyMedium?.copyWith(color: hintClr),
        labelStyle: textTheme.labelLarge?.copyWith(color: hintClr),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.input),
          borderSide: const BorderSide(color: NeuroColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.input),
          borderSide: BorderSide(color: errorClr),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.input),
          borderSide: BorderSide(color: errorClr, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.lg,
          vertical: NeuroSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryClr,
          foregroundColor: onPrimaryClr,
          disabledBackgroundColor: hintClr.withValues(alpha: 0.3),
          disabledForegroundColor: hintClr,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.xl,
            vertical: NeuroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.button),
          ),
          textStyle: NeuroTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryClr,
          disabledForegroundColor: hintClr,
          side: BorderSide(color: primaryClr),
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.xl,
            vertical: NeuroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.button),
          ),
          textStyle: NeuroTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryClr,
          disabledForegroundColor: hintClr,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
            vertical: NeuroSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.button),
          ),
          textStyle: NeuroTypography.button,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xxl),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: NeuroColors.textPrimary),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: NeuroColors.textBody),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NeuroColors.bgElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: NeuroColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NeuroColors.bgCard,
        labelStyle: textTheme.labelMedium?.copyWith(color: NeuroColors.textBody),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.md,
          vertical: NeuroSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.chip),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: dividerClr,
        thickness: 1,
        space: NeuroSpacing.lg,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryClr,
        linearTrackColor: dividerClr,
        circularTrackColor: dividerClr,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: NeuroColors.bgElevated,
          borderRadius: BorderRadius.circular(NeuroRadius.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: NeuroColors.textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.sm,
          vertical: NeuroSpacing.xs,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryClr;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimaryClr),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xs),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryClr;
          return hintClr;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryClr.withValues(alpha: 0.5);
          }
          return hintClr.withValues(alpha: 0.3);
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryClr;
          return hintClr;
        }),
      ),
    );
  }

  static ThemeData dark({required String fontFamily}) {
    return _baseTheme(
      brightness: Brightness.dark,
      scaffoldBg: NeuroColors.bgPrimary,
      surfaceColor: NeuroColors.bgSurface,
      appBarBg: NeuroColors.headerGradTop,
      appBarFg: NeuroColors.textPrimary,
      navBg: NeuroColors.navBg,
      navActive: NeuroColors.navActive,
      navInactive: NeuroColors.navInactive,
      primaryClr: NeuroColors.primary,
      primaryContainerClr: NeuroColors.primaryDark,
      onPrimaryClr: Colors.white,
      secondaryClr: NeuroColors.info,
      errorClr: NeuroColors.critical,
      onSurfaceClr: NeuroColors.textPrimary,
      inputFill: NeuroColors.bgInput,
      cardBg: NeuroColors.bgCard,
      dividerClr: NeuroColors.chartGrid,
      hintClr: NeuroColors.textSecondary,
    );
  }
}
