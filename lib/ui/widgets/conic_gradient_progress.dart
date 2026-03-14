import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConicGradientProgress extends CustomPainter {
  const ConicGradientProgress({required this.percentage, required this.color});

  final double percentage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Create conic gradient (SweepGradient in Flutter)
    // Adjust colors to match Dashy's: conic-gradient(themeColor winRate%, rgba(255,255,255,0.1) 0)
    paint.shader = SweepGradient(
      startAngle: -math.pi / 2, // Start at top
      endAngle: 3 * math.pi / 2, // Full circle relative to start
      colors: [
        color,
        color,
        Colors.white.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.1),
      ],
      stops: [0.0, percentage / 100.0, percentage / 100.0, 1.0],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant ConicGradientProgress oldDelegate) =>
      percentage != oldDelegate.percentage || color != oldDelegate.color;
}
