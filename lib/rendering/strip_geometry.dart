import 'dart:math';
import 'dart:ui';
import '../models/strip.dart';

/// Handles geometric calculations for strips, including path generation for rendering.
class StripGeometry {
  /// Generates the centerline path for a strip.
  /// The renderer should stroke this path with StrokeCap.round and StrokeJoin.round.
  static Path buildStripPath(Strip strip) {
    final path = Path();
    if (strip.points.isEmpty) return path;
    
    path.moveTo(strip.points.first.dx, strip.points.first.dy);
    for (int i = 1; i < strip.points.length; i++) {
      path.lineTo(strip.points[i].dx, strip.points[i].dy);
    }
    
    return path;
  }

  static Path buildSlitheringPath(Strip strip, double progress) {
    if (strip.points.isEmpty) return Path();
    if (strip.points.length == 1) {
      final p = strip.points.first;
      return Path()..moveTo(p.dx, p.dy)..lineTo(p.dx, p.dy);
    }
    
    final head = strip.points.last;
    final preHead = strip.points[strip.points.length - 2];
    
    Offset dir = head - preHead;
    double dirLen = dir.distance;
    if (dirLen == 0) {
      dir = const Offset(1, 0); 
    } else {
      dir = dir / dirLen;
    }
    
    double totalLength = 0;
    final lengths = <double>[0];
    for (int i = 1; i < strip.points.length; i++) {
      final d = (strip.points[i] - strip.points[i-1]).distance;
      totalLength += d;
      lengths.add(totalLength);
    }
    
    // The strip slides out completely. 1500 logical pixels guarantees it goes offscreen.
    final slideDistance = progress * (totalLength + 1500.0);
    final startDist = slideDistance; // Tail
    final endDist = slideDistance + totalLength; // Head
    
    final path = Path();
    
    Offset getPointAtDistance(double d) {
      if (d <= 0) return strip.points.first;
      if (d >= totalLength) {
        final extra = d - totalLength;
        return head + dir * extra;
      }
      for (int i = 1; i < strip.points.length; i++) {
        if (d <= lengths[i]) {
          final t = (d - lengths[i-1]) / (lengths[i] - lengths[i-1]);
          return Offset.lerp(strip.points[i-1], strip.points[i], t)!;
        }
      }
      return head; 
    }
    
    final tailPos = getPointAtDistance(startDist);
    path.moveTo(tailPos.dx, tailPos.dy);
    
    for (int i = 1; i < strip.points.length; i++) {
      if (lengths[i] > startDist && lengths[i] < endDist) {
        path.lineTo(strip.points[i].dx, strip.points[i].dy);
      }
    }
    
    final headPos = getPointAtDistance(endDist);
    path.lineTo(headPos.dx, headPos.dy);
    
    return path;
  }

  /// Calculates the bounding box containing all strips in a level
  static Rect getLevelBounds(List<Strip> strips) {
    if (strips.isEmpty) return Rect.zero;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final strip in strips) {
      for (final p in strip.points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    // Add margin for the thickness of the strips
    const maxHalfWidth = 20.0;
    return Rect.fromLTRB(minX - maxHalfWidth, minY - maxHalfWidth, maxX + maxHalfWidth, maxY + maxHalfWidth);
  }

  /// Calculates the shortest distance from a point to a line segment
  static double distanceToSegment(Offset point, Offset start, Offset end) {
    final l2 = (end.dx - start.dx) * (end.dx - start.dx) + (end.dy - start.dy) * (end.dy - start.dy);
    if (l2 == 0) {
      return (point - start).distance;
    }
    
    double t = ((point.dx - start.dx) * (end.dx - start.dx) + (point.dy - start.dy) * (end.dy - start.dy)) / l2;
    t = max(0, min(1, t));
    
    final proj = Offset(start.dx + t * (end.dx - start.dx), start.dy + t * (end.dy - start.dy));
    return (point - proj).distance;
  }

  /// Calculates the shortest distance from a point to any segment in a strip.
  static double distanceToStrip(Offset point, Strip strip) {
    if (strip.points.isEmpty) return double.infinity;
    if (strip.points.length == 1) return (point - strip.points.first).distance;
    
    double minDistance = double.infinity;
    for (int i = 0; i < strip.points.length - 1; i++) {
      final p1 = strip.points[i];
      final p2 = strip.points[i + 1];
      final d = distanceToSegment(point, p1, p2);
      if (d < minDistance) {
        minDistance = d;
      }
    }
    return minDistance;
  }

  /// Checks if a point hits the thickened strip
  static bool hitTestStrip(Offset point, Strip strip) {
    final threshold = strip.width / 2.0;
    return distanceToStrip(point, strip) <= threshold;
  }
}
