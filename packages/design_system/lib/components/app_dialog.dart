import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

class AppDialog {
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xl),
        ),
        elevation: 24,
        shadowColor: NeuroShadows.modal.color,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous
                  ? NeuroColors.critical
                  : NeuroColors.primary,
              foregroundColor: NeuroColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NeuroRadius.md),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  static void showAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xl),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeuroColors.primary,
              foregroundColor: NeuroColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NeuroRadius.md),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> showCriticalAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeuroRadius.xl),
        ),
        backgroundColor: NeuroColors.critical.withAlpha(20),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded,
                color: NeuroColors.critical, size: 28),
            const SizedBox(width: NeuroSpacing.sm),
            Expanded(
              child: Text(title,
                  style: const TextStyle(color: NeuroColors.critical)),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: NeuroColors.critical,
              foregroundColor: NeuroColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NeuroRadius.md),
              ),
            ),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }
}
