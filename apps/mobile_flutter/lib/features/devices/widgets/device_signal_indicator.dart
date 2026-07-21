import 'package:flutter/material.dart';

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
    if (signalStrength >= -70) return const Color(0xFF4CAF50);
    if (signalStrength >= -85) return const Color(0xFFF57C00);
    return const Color(0xFFE53935);
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
            painter: _SignalBarsPainter(bars: bars, color: color),
          ),
        ),
        SizedBox(width: 4),
        Text(
          '${signalStrength.toInt()} dBm',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SignalBarsPainter extends CustomPainter {
  final int bars;
  final Color color;

  _SignalBarsPainter({required this.bars, required this.color});

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

      paint.color = i < bars ? color : Colors.grey.withValues(alpha: 0.3);

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
    return oldDelegate.bars != bars || oldDelegate.color != color;
  }
}
