
import 'package:flutter/material.dart';
import '../models/strip.dart';
import 'strip_geometry.dart';

class IsolatedStripPainter extends CustomPainter {
  final Strip strip;
  final double scale;
  final Offset logicalOffset;

  IsolatedStripPainter({
    required this.strip,
    required this.scale,
    required this.logicalOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale, scale);
    canvas.translate(-logicalOffset.dx, -logicalOffset.dy);

    final path = StripGeometry.buildStripPath(strip);
    final w = strip.width;

    // Rim light (bottom layer)
    final rimPaint = Paint()
      ..color = const Color(0xFF3A3A3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w + 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, rimPaint);

    // Dark edges (outer layer of the tube)
    final darkPaint = Paint()
      ..color = const Color(0xFF121212)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, darkPaint);

    // Mid-light (middle layer)
    final midPaint = Paint()
      ..color = const Color(0xFF1A1A1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, midPaint);

    // Highlight (inner center layer)
    final centerPaint = Paint()
      ..color = const Color(0xFF2C2C2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, centerPaint);
  }

  @override
  bool shouldRepaint(covariant IsolatedStripPainter oldDelegate) {
    return false;
  }
}

