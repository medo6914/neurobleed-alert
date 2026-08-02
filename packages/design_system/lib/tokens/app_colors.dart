import 'package:flutter/material.dart';

class NeuroColors {
  NeuroColors._();

  // Background ⚡ pixel-verified
  static const Color bgPrimary = Color(0xFF000A1C);
  static const Color bgSurface = Color(0xFF010D24);
  static const Color bgCard = Color(0xFF000A20);
  static const Color bgElevated = Color(0xFF0A1C38);
  static const Color bgInput = Color(0xFF071835);

  // Primary ⚡ pixel-verified
  static const Color primary = Color(0xFF1B409A);
  static const Color primaryLight = Color(0xFF2A5A9A);
  static const Color primaryDark = Color(0xFF1030B0);
  static const Color primaryGlass = Color(0xFF061B44);

  // Semantic ⚡ = verified, ≈ = estimated
  static const Color critical = Color(0xFFD01010);
  static const Color criticalBright = Color(0xFFF01010);
  static const Color high = Color(0xFFF07010);
  static const Color medium = Color(0xFFD0B010);
  static const Color low = Color(0xFF10B050);
  static const Color success = Color(0xFF10F050);
  static const Color info = Color(0xFF0883B9);

  // Text ⚡ pixel-verified
  static const Color textPrimary = Color(0xFFECF1F7);
  static const Color textBody = Color(0xFFC9D2E1);
  static const Color textSecondary = Color(0xFF8892A8);
  static const Color textOnDark = Color(0xFFD4DBE8);

  // Navigation ⚡ pixel-verified
  static const Color navBg = Color(0xFF010A1E);
  static const Color navActive = Color(0xFF1B409A);
  static const Color navInactive = Color(0xFF505070);

  // Gradient headers ⚡ pixel-verified
  static const Color headerGradTop = Color(0xFF020C23);
  static const Color headerGradBottom = Color(0xFF29354E);
  static const Color cardGradTop = Color(0xFF020F27);
  static const Color cardGradBottom = Color(0xFF04122D);

  // Charts ⚡ pixel-verified
  static const Color chartBlue = Color(0xFF1B409A);
  static const Color chartFill = Color(0xFF081F52);
  static const Color chartLine = Color(0xFFC9D2E1);
  static const Color chartThreshold = Color(0xFFD01010);
  static const Color chartGrid = Color(0xFF1A2A4A);

  // Backward-compat aliases
  static const Color background = bgPrimary;
  static const Color surface = bgSurface;
  static const Color surfaceDark = bgElevated;
  static const Color backgroundDark = bgPrimary;
  static const Color warning = high;
  static const Color stable = low;
  static const Color monitoring = info;
  static const Color error = critical;
  static const Color textOnPrimary = textPrimary;
  static const Color heartRate = critical;
  static const Color oxygenSaturation = primary;
  static const Color bloodPressureSystolic = high;
  static const Color bloodPressureDiastolic = medium;
  static const Color temperature = Color(0xFF9C27B0);
  static const Color respiratoryRate = low;
  static const Color icp = Color(0xFFE91E63);
  static const Color cpp = primaryLight;
}
