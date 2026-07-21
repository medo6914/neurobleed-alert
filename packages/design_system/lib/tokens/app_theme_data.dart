import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_shadows.dart';
import 'app_radius.dart';

class NeuroThemeData {
  NeuroThemeData._();

  static ThemeData light({required String fontFamily}) {
    final colorScheme = ColorScheme.light(
      primary: NeuroColors.primary,
      onPrimary: NeuroColors.textOnPrimary,
      primaryContainer: NeuroColors.primaryLight,
      secondary: NeuroColors.info,
      error: NeuroColors.error,
      surface: NeuroColors.surface,
      onSurface: NeuroColors.textPrimary,
    );

    final textTheme = NeuroTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: NeuroColors.background,
      cardTheme: CardThemeData(
        color: NeuroColors.surface,
        elevation: 2,
        shadowColor: NeuroShadows.card.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: NeuroColors.surface,
        foregroundColor: NeuroColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: NeuroColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: NeuroColors.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: NeuroColors.surface,
        selectedItemColor: NeuroColors.primary,
        unselectedItemColor: NeuroColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: NeuroColors.primary,
        foregroundColor: NeuroColors.textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xl),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeuroColors.background,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: NeuroColors.textSecondary,
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: NeuroColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.chartGrid),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.chartGrid),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.lg,
          vertical: NeuroSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeuroColors.primary,
          foregroundColor: NeuroColors.textOnPrimary,
          disabledBackgroundColor: NeuroColors.chartGrid,
          disabledForegroundColor: NeuroColors.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.xl,
            vertical: NeuroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NeuroColors.primary,
          disabledForegroundColor: NeuroColors.textSecondary,
          side: const BorderSide(color: NeuroColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.xl,
            vertical: NeuroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NeuroColors.primary,
          disabledForegroundColor: NeuroColors.textSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
            vertical: NeuroSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: NeuroColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xl),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: NeuroColors.textPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: NeuroColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NeuroColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: NeuroColors.textOnPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NeuroColors.background,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: NeuroColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.sm,
          vertical: NeuroSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.full),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: NeuroColors.chartGrid,
        thickness: 1,
        space: NeuroSpacing.lg,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: NeuroColors.primary,
        linearTrackColor: NeuroColors.chartGrid,
        circularTrackColor: NeuroColors.chartGrid,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: NeuroColors.textPrimary,
          borderRadius: BorderRadius.circular(NeuroRadius.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: NeuroColors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.sm,
          vertical: NeuroSpacing.xs,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(NeuroColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.sm),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primary;
          }
          return NeuroColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primaryLight;
          }
          return NeuroColors.chartGrid;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primary;
          }
          return NeuroColors.textSecondary;
        }),
      ),
    );
  }

  static ThemeData dark({required String fontFamily}) {
    final colorScheme = ColorScheme.dark(
      primary: NeuroColors.primaryLight,
      onPrimary: NeuroColors.textPrimary,
      primaryContainer: NeuroColors.primaryDark,
      secondary: NeuroColors.info,
      error: NeuroColors.error,
      surface: NeuroColors.surfaceDark,
      onSurface: NeuroColors.textOnPrimary,
    );

    final textTheme = NeuroTypography.textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme.apply(
        bodyColor: NeuroColors.textOnPrimary,
        displayColor: NeuroColors.textOnPrimary,
      ),
      scaffoldBackgroundColor: NeuroColors.backgroundDark,
      cardTheme: CardThemeData(
        color: NeuroColors.surfaceDark,
        elevation: 2,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: NeuroColors.surfaceDark,
        foregroundColor: NeuroColors.textOnPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: NeuroColors.textOnPrimary,
        ),
        iconTheme: const IconThemeData(color: NeuroColors.textOnPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: NeuroColors.surfaceDark,
        selectedItemColor: NeuroColors.primaryLight,
        unselectedItemColor: NeuroColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: NeuroColors.primaryLight,
        foregroundColor: NeuroColors.textPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xl),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeuroColors.backgroundDark,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: NeuroColors.textSecondary,
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: NeuroColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.textSecondary, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.textSecondary, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
          borderSide: const BorderSide(color: NeuroColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.lg,
          vertical: NeuroSpacing.md,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeuroColors.primaryLight,
          foregroundColor: NeuroColors.textPrimary,
          disabledBackgroundColor: NeuroColors.textSecondary.withValues(alpha: 0.3),
          disabledForegroundColor: NeuroColors.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.xl,
            vertical: NeuroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NeuroColors.primaryLight,
          disabledForegroundColor: NeuroColors.textSecondary,
          side: const BorderSide(color: NeuroColors.primaryLight),
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.xl,
            vertical: NeuroSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NeuroColors.primaryLight,
          disabledForegroundColor: NeuroColors.textSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: NeuroSpacing.lg,
            vertical: NeuroSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuroRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: NeuroColors.surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xl),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: NeuroColors.textOnPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: NeuroColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: NeuroColors.textOnPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NeuroColors.backgroundDark,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: NeuroColors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.sm,
          vertical: NeuroSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.full),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: NeuroColors.textSecondary.withValues(alpha: 0.3),
        thickness: 1,
        space: NeuroSpacing.lg,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: NeuroColors.primaryLight,
        linearTrackColor: NeuroColors.textSecondary.withValues(alpha: 0.3),
        circularTrackColor: NeuroColors.textSecondary.withValues(alpha: 0.3),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: NeuroColors.textSecondary,
          borderRadius: BorderRadius.circular(NeuroRadius.sm),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: NeuroColors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: NeuroSpacing.sm,
          vertical: NeuroSpacing.xs,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(NeuroColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.sm),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primaryLight;
          }
          return NeuroColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primaryLight.withValues(alpha: 0.5);
          }
          return NeuroColors.textSecondary.withValues(alpha: 0.3);
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NeuroColors.primaryLight;
          }
          return NeuroColors.textSecondary;
        }),
      ),
    );
  }
}
