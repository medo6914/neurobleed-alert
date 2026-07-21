import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class AppInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool enabled;

  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NeuroTypography.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.labelLarge),
        const SizedBox(height: NeuroSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          style: theme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: NeuroColors.background,
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
              borderSide:
                  const BorderSide(color: NeuroColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NeuroRadius.md),
              borderSide: const BorderSide(color: NeuroColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NeuroRadius.md),
              borderSide:
                  const BorderSide(color: NeuroColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: NeuroSpacing.lg,
              vertical: NeuroSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}
