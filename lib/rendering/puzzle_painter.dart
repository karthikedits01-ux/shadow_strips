import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
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
  final ui.Image? noiseTexture;

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
    this.noiseTexture,
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

    if (stripState == StripState.removed) return;

    final removalValue = removalAnimations[strip.id] ?? 0.0;
    
    // 1. Use the Slithering Path if it's being removed
    final path = removalValue > 0 
        ? StripGeometry.buildSlitheringPath(strip, removalValue) 
        : StripGeometry.buildStripPath(strip);

    canvas.saveLayer(null, Paint()); // Use SaveLayer to mask shadows cleanly

    // We no longer scale down and fade out. The slithering path takes care of the exit!
    int alpha = 255;
    if (removalValue > 0) {
      // Fade out slightly at the very end of the animation to ensure clean cleanup
      if (removalValue > 0.8) {
        alpha = (255 * (1.0 - (removalValue - 0.8) * 5)).toInt().clamp(0, 255);
      }
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

    // 4. 3D Bevel Highlight (Exclusive to top/left edges)
    // Drawn offset by (-1, -1). The main fill drawn at (0,0) covers the bottom-right side completely!
    final highlightPaint = Paint()
      ..color = const Color(0x66FFFFFF) // Semi-transparent white highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path.shift(const Offset(-1.0, -1.0)), highlightPaint);

    // 1 & 3. Lightened Base Color with Directional Lighting (Gradient)
    final Rect bounds = path.getBounds();
    final LinearGradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        errorValue > 0 ? Colors.red[400]! : const Color(0xFF5A5A5A), // Lighter Charcoal
        errorValue > 0 ? Colors.red[900]! : const Color(0xFF353535), // Darker Charcoal
      ],
    );
    final gradientPaint = Paint()
      ..shader = gradient.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w 
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, gradientPaint);

    // 2. Enhance Texture Contrast
    if (noiseTexture != null) {
      final Float64List matrix = Float64List.fromList([
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
      ]);
      
      final noisePaint = Paint()
        ..shader = ui.ImageShader(
          noiseTexture!,
          TileMode.repeated,
          TileMode.repeated,
          matrix,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.multiply; // Multiply creates strong contrast for the light grey noise
        
      canvas.drawPath(path, noisePaint);
    }

    // Sharp Paper-Cut Arrowhead
    if (removalValue == 0 && strip.points.length >= 2) {
      final head = strip.points.last;
      final preHead = strip.points[strip.points.length - 2];
      Offset dir = head - preHead;
      double dirLen = dir.distance;
      if (dirLen > 0) {
        dir = dir / dirLen;
        final arrowSize = w * 0.45;
        final arrowTip = head - dir * (w * 0.1); 
        final p1 = arrowTip - dir * arrowSize + Offset(-dir.dy, dir.dx) * (arrowSize * 0.7);
        final p3 = arrowTip - dir * arrowSize - Offset(-dir.dy, dir.dx) * (arrowSize * 0.7);
        
        final arrowPath = Path()..moveTo(p1.dx, p1.dy)..lineTo(arrowTip.dx, arrowTip.dy)..lineTo(p3.dx, p3.dy)..close();
        
        final arrowPaint = Paint()
          ..color = errorValue > 0 ? Colors.redAccent[100]!.withAlpha(alpha) : const Color(0xFFE5E5EA).withAlpha(alpha)
          ..style = PaintingStyle.fill;
          
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }

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
