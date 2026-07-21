import 'package:flutter/material.dart';

class NeuroCurves {
  NeuroCurves._();

  static const Curve defaultCurve = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve emphasize = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasizeDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizeAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
}
