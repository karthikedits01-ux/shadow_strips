import 'dart:ui';
import '../models/game_state.dart';
import '../models/strip.dart';
import 'strip_geometry.dart';
import 'puzzle_layout.dart';

class HitTestEngine {
  /// Converts a physical screen tap coordinate to logical board coordinates
  /// based on the scaling applied during rendering.
  static Offset physicalToLogical(
    Offset physicalTap,
    Size screenSize,
    Rect bounds,
    String levelId,
    double safeAreaTop,
    double safeAreaBottom,
  ) {
    if (bounds.isEmpty) return physicalTap;
    
    final transform = PuzzleLayout.calculateTransform(
      screenSize: screenSize,
      bounds: bounds,
      levelId: levelId,
      safeAreaTop: safeAreaTop,
      safeAreaBottom: safeAreaBottom,
    );

    // Apply inverse transform
    // Forward transform was: translate(translateX, translateY), then scale(scale)
    // Point p' = (p * scale) + (translateX, translateY)
    // So p = (p' - (translateX, translateY)) / scale
    
    final logicalX = (physicalTap.dx - transform.translateX) / transform.scale;
    final logicalY = (physicalTap.dy - transform.translateY) / transform.scale;
    
    return Offset(logicalX, logicalY);
  }

  /// Determines which strip was tapped, returning its ID.
  /// Handles:
  /// 1. Direct hits on strip body (returns topmost visible strip in drawOrder at crossings).
  /// 2. Near-misses within zoom-adaptive touch tolerance (returns closest strip to prevent mis-selecting adjacent strips).
  static String? hitTest(
    Offset logicalTap,
    GameState state, {
    double physicalScale = 1.0,
  }) {
    final activeStrips = state.activeStrips.values.toList();
    if (activeStrips.isEmpty) return null;

    // Physical touch tolerance buffer: 14.0 physical screen pixels
    // Converted dynamically to logical units based on effective rendering scale
    final effectiveScale = physicalScale > 0 ? physicalScale : 1.0;
    final touchTolerance = (14.0 / effectiveScale).clamp(6.0, 40.0);

    final directHits = <Strip>[];
    final touchHits = <Strip>[];
    final distances = <String, double>{};

    for (final strip in activeStrips) {
      final d = StripGeometry.distanceToStrip(logicalTap, strip);
      distances[strip.id] = d;

      final bodyRadius = strip.width / 2.0;
      if (d <= bodyRadius) {
        directHits.add(strip);
      } else if (d <= bodyRadius + touchTolerance) {
        touchHits.add(strip);
      }
    }

    // 1. Direct Hit on visual strip body (e.g. crossing) -> topmost strip wins
    if (directHits.isNotEmpty) {
      directHits.sort((a, b) {
        final orderA = state.drawOrder.indexOf(a.id);
        final orderB = state.drawOrder.indexOf(b.id);
        if (orderA != -1 && orderB != -1) {
          return orderB.compareTo(orderA); // Highest drawOrder index is on top
        }
        return b.zIndex.compareTo(a.zIndex);
      });
      return directHits.first.id;
    }

    // 2. Near-miss within touch tolerance -> closest strip wins
    if (touchHits.isNotEmpty) {
      touchHits.sort((a, b) {
        final distA = distances[a.id] ?? double.infinity;
        final distB = distances[b.id] ?? double.infinity;
        final diff = distA - distB;
        if (diff.abs() < 2.0) {
          // Equidistant tie-break by topmost
          final orderA = state.drawOrder.indexOf(a.id);
          final orderB = state.drawOrder.indexOf(b.id);
          if (orderA != -1 && orderB != -1) {
            return orderB.compareTo(orderA);
          }
          return b.zIndex.compareTo(a.zIndex);
        }
        return distA.compareTo(distB);
      });
      return touchHits.first.id;
    }

    return null;
  }
}
