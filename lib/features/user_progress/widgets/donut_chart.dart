import 'dart:math';
import 'package:flutter/material.dart';

/// A simple circular donut chart with a percentage label in the centre.
class DonutChart extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double size;
  final double strokeWidth;

  const DonutChart({
    super.key,
    required this.value,
    required this.color,
    this.size = 64,
    this.strokeWidth = 7,
  });

  @override
  Widget build(BuildContext context) {
    final pct = '${(value * 100).round()}%';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              value: value,
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
          Text(
            pct,
            style: TextStyle(
              fontSize: size * 0.20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double value;
  final Color color;
  final double strokeWidth;

  const _DonutPainter({
    required this.value,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sw = strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - sw) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );

    // Foreground arc
    if (value > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * value.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.value != value || old.color != color || old.strokeWidth != strokeWidth;
}
