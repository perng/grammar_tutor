import 'package:flutter/material.dart';

class PieChartPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;

  PieChartPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground pie
    if (percentage > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // Start at -90 degrees (12 o'clock)
        2 * 3.14159 * percentage,
        true, // Use center for pie slice
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.bgColor != bgColor;
  }
}
