import 'package:flutter/material.dart';

class AppFormBuilder extends Form {
  AppFormBuilder({
    super.key,
    required super.child,
    super.autovalidateMode,
    super.onChanged,
    super.onPopInvokedWithResult,
  });

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? validateRequired(String? value,
      {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final regex = RegExp(r'^\+?[\d\s-]{8,15}$');
    if (!regex.hasMatch(value)) return 'Enter a valid phone number';
    return null;
  }

  static String? validateNumeric(String? value) {
    if (value == null || value.isEmpty) return 'Value is required';
    if (double.tryParse(value) == null) return 'Enter a valid number';
    return null;
  }

  static String? validateMrn(String? value) {
    if (value == null || value.isEmpty) return 'MRN is required';
    return null;
  }

  static String? matchFields(String? value, String? otherValue,
      {String fieldName = 'Fields'}) {
    if (value != otherValue) return '$fieldName do not match';
    return null;
  }
}
