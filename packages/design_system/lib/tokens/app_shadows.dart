import 'package:flutter/material.dart';

class NeuroShadows {
  NeuroShadows._();

  static const BoxShadow card = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow elevated = BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow modal = BoxShadow(
    color: Color(0x66000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static const BoxShadow alert = BoxShadow(
    color: Color(0x4DD01010),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}
