import 'package:flutter/material.dart';

class NeuroShadows {
  NeuroShadows._();

  static const BoxShadow card = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow elevated = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow modal = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static const BoxShadow alert = BoxShadow(
    color: Color(0x4DD32F2F),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}
