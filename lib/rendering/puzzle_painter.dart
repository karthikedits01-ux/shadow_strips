import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/strip.dart';
import '../models/puzzle_level.dart';
import 'strip_geometry.dart';
import 'shadow_renderer.dart';
import 'puzzle_layout.dart';

class PuzzlePainter extends CustomPainter {
  final GameState state;
  final double logicalWidth;
  final double logicalHeight;
  final double safeAreaTop;
  final double safeAreaBottom;

  // Animation values injected from the widget
  final Map<String, double> removalAnimations;
  final Map<String, double> errorAnimations;
  final PuzzleLevel level;
  final double tutorialPulseValue;

  PuzzlePainter({
    required this.state,
    required this.level,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.removalAnimations,
    required this.errorAnimations,
    this.safeAreaTop = 0,
    this.safeAreaBottom = 0,
    this.tutorialPulseValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = StripGeometry.getLevelBounds(level.strips);
    if (bounds.isEmpty) return;

    final transform = PuzzleLayout.calculateTransform(
      screenSize: size,
      bounds: bounds,
      levelId: level.levelId,
      safeAreaTop: safeAreaTop,
      safeAreaBottom: safeAreaBottom,
    );

    // Save canvas state before global transform
    canvas.save();
    canvas.translate(transform.translateX, transform.translateY);
    canvas.scale(transform.scale, transform.scale);

    // Sort strips deterministically by logical topological drawOrder
    final sortedStrips = state.activeStrips.values.toList()
      ..sort(
        (a, b) => state.drawOrder
            .indexOf(a.id)
            .compareTo(state.drawOrder.indexOf(b.id)),
      );

    // 1. Paint all floor shadows first
    ShadowRenderer.paintFloorShadows(
      canvas,
      sortedStrips,
      level,
      removalAnimations,
      state.drawOrder,
    );

    // 2. Paint strips in Z-order
    for (final strip in sortedStrips) {
      _paintStrip(canvas, strip, sortedStrips);
    }

    // 3. Draw Tutorial Overlay (if active)
    if (tutorialPulseValue > 0) {
      // Find the highest free strip to indicate to the player
      Strip? targetStrip;
      for (final strip in sortedStrips.reversed) {
        if (state.stripStates[strip.id] == StripState.free) {
          targetStrip = strip;
          break;
        }
      }

      if (targetStrip != null) {
        final path = StripGeometry.buildStripPath(targetStrip);
        final center = path.getBounds().center;

        final pulsePaint = Paint()
          ..color = Colors.white.withValues(alpha: tutorialPulseValue)
          ..style = PaintingStyle.fill;

        final pulseRadius =
            30.0 + ((tutorialPulseValue - 0.1) / 0.3) * 15.0; // scales 30 to 45

        canvas.drawCircle(center, pulseRadius, pulsePaint);
      }
    }

    // Restore canvas
    canvas.restore();
  }

  void _paintStrip(Canvas canvas, Strip strip, List<Strip> activeStrips) {
    final stripState = state.stripStates[strip.id];

    // Only paint if not fully removed. (State map tracking logic)
    if (stripState == StripState.removed) return;

    final path = StripGeometry.buildStripPath(strip);

    canvas.saveLayer(null, Paint()); // Use SaveLayer to mask shadows cleanly

    // 1. Apply Removal Animation Transform (Scale down and Fade out)
    final removalValue = removalAnimations[strip.id] ?? 0.0;
    int alpha = 255;
    if (removalValue > 0) {
      final bounds = path.getBounds();
      final centerX = bounds.center.dx;
      final centerY = bounds.center.dy;

      canvas.translate(centerX, centerY);
      final scale = 1.0 - (removalValue * 0.2); // Scale down to 0.8
      canvas.scale(scale, scale);
      canvas.translate(-centerX, -centerY);

      alpha = (255 * (1.0 - removalValue)).toInt();
    }

    // 2. Apply Error Animation Transform (wiggle on collision)
    final errorValue = errorAnimations[strip.id] ?? 0.0;
    if (errorValue > 0) {
      // Wiggle physically. Sine wave.
      final offset = 8.0 * (1.0 - errorValue) * (errorValue * 30).sin();
      canvas.translate(offset, 0); // Simplified wiggle on X
    }

    final w = strip.width;

    // 3. Draw Tactile 3D Volume (Layered strokes to simulate 3D gradient along path)

    // Rim light (bottom layer)
    final rimPaint = Paint()
      ..color = const Color(0xFF3A3A3C).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w + 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, rimPaint);

    // Dark edges (outer layer of the tube)
    final darkPaint = Paint()
      ..color = const Color(0xFF121212).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, darkPaint);

    // Mid-light (middle layer)
    final midPaint = Paint()
      ..color = const Color(0xFF1A1A1C).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, midPaint);

    // Highlight (inner center layer)
    final centerPaint = Paint()
      ..color = const Color(0xFF2C2C2E).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, centerPaint);

    // 4. Draw Shadows from higher strips onto THIS strip using SrcATop so it only paints over the strip
    canvas.saveLayer(null, Paint()..blendMode = BlendMode.srcATop);
    ShadowRenderer.paintShadowsOnStrip(
      canvas,
      strip,
      activeStrips,
      level,
      removalAnimations,
      state.drawOrder,
    );
    canvas.restore();

    canvas.restore(); // Restore the outer SaveLayer
  }

  @override
  bool shouldRepaint(covariant PuzzlePainter oldDelegate) {
    // In production, we'd do a deeper equality check or just rely on the controller notifying.
    // For now, always repaint when called by the animation builder.
    return true;
  }
}

// Extension for sine on doubles
extension SineExtension on double {
  double sin() => math.sin(this);
}
