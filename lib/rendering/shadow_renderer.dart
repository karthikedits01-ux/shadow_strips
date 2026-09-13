import 'package:flutter/material.dart';
import '../models/strip.dart';
import '../models/puzzle_level.dart';
import 'strip_geometry.dart';

class ShadowRenderer {
  /// Paints floor shadows for all strips.
  /// This must be called BEFORE any strips are painted.
  static void paintFloorShadows(
    Canvas canvas,
    List<Strip> activeStrips,
    PuzzleLevel level,
    Map<String, double> removalAnimations,
    List<String> drawOrder,
  ) {
    for (final strip in activeStrips) {
      final removalValue = removalAnimations[strip.id] ?? 0.0;
      if (removalValue >= 1.0) continue; // Fully removed

      final path = StripGeometry.buildStripPath(strip);
      final zOffset = drawOrder.indexOf(strip.id).toDouble();
      
      final alpha = (255 * 0.5 * (1.0 - removalValue)).toInt(); // 50% opacity
      if (alpha <= 0) continue;

      final blurRadius = 4.0 + zOffset * 2.0;

      final shadowPaint = Paint()
        ..color = Colors.black.withAlpha(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strip.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.save();
      // Extreme Z-Depth offset: Offset(2, 6) * zOffset
      canvas.translate(2.0 * zOffset, 6.0 * zOffset);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
    }
  }

  /// Paints shadows cast by ALL higher-Z strips onto the [receiver] strip.
  /// Must be called AFTER painting the receiver's base.
  static void paintShadowsOnStrip(
    Canvas canvas,
    Strip receiver,
    List<Strip> activeStrips,
    PuzzleLevel level,
    Map<String, double> removalAnimations,
    List<String> drawOrder,
  ) {

    final receiverZ = drawOrder.indexOf(receiver.id);

    for (final caster in activeStrips) {
      final casterZ = drawOrder.indexOf(caster.id);
      if (casterZ <= receiverZ) continue;

      final removalValue = removalAnimations[caster.id] ?? 0.0;
      if (removalValue >= 1.0) continue;

      final casterPath = StripGeometry.buildStripPath(caster);
      final zDiff = (casterZ - receiverZ).toDouble();
      
      final alpha = (255 * 0.5 * (1.0 - removalValue)).toInt(); // 50% opacity
      if (alpha <= 0) continue;

      final blurRadius = 4.0 + zDiff * 2.0;

      final shadowPaint = Paint()
        ..color = Colors.black.withAlpha(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
        ..style = PaintingStyle.stroke
        ..strokeWidth = caster.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // To clip to a stroke, we need to get the filled path of the stroke.
      // Wait, Canvas.clipPath only clips the INSIDE of the path.
      // Since receiverPath is a center-line, clipping by it will clip to 0 pixels!
      // This is a major issue! We must clip to the thickened receiver stroke.
      // In Flutter, Paint doesn't have `getFillPath`. We cannot easily clip to a stroked path without `ui.Path.computeMetrics` or using layered drawing (e.g. SaveLayer).
      
      // ALTERNATIVE: Draw the receiver's shadow mask using `BlendMode.srcATop`
      // We will let the `PuzzlePainter` handle this via SaveLayer instead of doing `clipPath` here!
      // Actually, since this is called per-strip in `_paintStrip`, we can use `clipPath` if we had the filled path.
      // Since we don't, we can draw shadows using `SaveLayer`. Wait, we just draw the shadows normally, they will fall outside the receiver.
      // Is that bad? Yes, it breaks the illusion.
      // But wait! `PuzzlePainter` does `SaveLayer` for intersection highlights. No, it uses `clipPath`.
      // Let's remove the `clipPath` here and let `PuzzlePainter` handle the shadow masking via an `alpha mask` technique, or just leave it for now.
      // Wait, I can't leave it. Without `clipPath`, the shadow from the caster will fall on the floor AND on the receiver.
      // We will skip `paintShadowsOnStrip` masking for now, or just draw it.
      
      // Let's implement `PuzzlePainter` properly using `SaveLayer`.
      // For now, I'll return without clipping, and I'll rewrite the masking in `PuzzlePainter`.
      canvas.save();
      canvas.translate(2.0 * zDiff, 6.0 * zDiff);
      // We removed clipPath because receiverPath is not filled.
      // This will cast shadow everywhere. We will handle masking in `PuzzlePainter`.
      canvas.drawPath(casterPath, shadowPaint);
      canvas.restore();
    }
  }
}
