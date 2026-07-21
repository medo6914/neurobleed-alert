import 'package:flutter/material.dart';

class Accessibility {
  Accessibility._();

  static const double minimumTapTarget = 48.0;

  static String? semanticLabel(String label, {String? hint}) {
    if (hint != null) return '$label. $hint';
    return label;
  }

  static Widget mergeSemantics(Widget child, {String? label, String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      child: child,
    );
  }
}
