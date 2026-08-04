import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class DeviceSignalIndicator extends StatelessWidget {
  final double signalStrength;

  const DeviceSignalIndicator({
    super.key,
    required this.signalStrength,
  });

  int _barCount() {
    if (signalStrength >= -50) return 4;
    if (signalStrength >= -70) return 3;
    if (signalStrength >= -85) return 2;
    if (signalStrength >= -100) return 1;
    return 0;
  }

  Color _signalColor() {
    if (signalStrength >= -70) return NeuroColors.success;
    if (signalStrength >= -85) return NeuroColors.high;
    return NeuroColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    final bars = _barCount();
    final color = _signalColor();
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 14,
          child: CustomPaint(
            painter: _SignalBarsPainter(
              bars: bars,
              color: color,
              inactiveColor: NeuroColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
        ),
        SizedBox(width: 4),
        Text(
          '${signalStrength.toInt()} dBm',
          style: theme.textTheme.labelSmall?.copyWith(
            color: NeuroColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SignalBarsPainter extends CustomPainter {
  final int bars;
  final Color color;
  final Color inactiveColor;

  _SignalBarsPainter({
    required this.bars,
    required this.color,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 5;
    final gap = barWidth * 0.3;

    for (int i = 0; i < 4; i++) {
      final barHeight = (size.height / 4) * (i + 1);
      final x = i * (barWidth + gap) + gap;
      final y = size.height - barHeight;

      paint.color = i < bars ? color : inactiveColor;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          topLeft: Radius.circular(1),
          topRight: Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalBarsPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.color != color ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
