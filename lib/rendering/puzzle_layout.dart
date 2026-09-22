import 'dart:ui';
import 'dart:math' as math;

class PuzzleTransform {
  final double scale;
  final double translateX;
  final double translateY;

  const PuzzleTransform({
    required this.scale,
    required this.translateX,
    required this.translateY,
  });
}

class PuzzleLayout {
  /// Calculates the transformation needed to render or hit-test the puzzle
  /// inside the given [screenSize].
  static PuzzleTransform calculateTransform({
    required Size screenSize,
    required Rect bounds,
    required String levelId,
    double safeAreaTop = 0,
    double safeAreaBottom = 0,
  }) {
    if (bounds.isEmpty) {
      return const PuzzleTransform(scale: 1.0, translateX: 0.0, translateY: 0.0);
    }

    final levelNum = int.tryParse(levelId.split('_').last) ?? 0;
    final isFixedCanvas = levelNum >= 22;
    final isAdaptiveScale = levelNum >= 1 && levelNum <= 12;

    final actualWidth = bounds.width;
    final actualHeight = bounds.height;

    final hudSafeTop = safeAreaTop + 80.0;
    final navSafeBottom = safeAreaBottom + 20.0;
    final playableWidth = screenSize.width;
    final playableHeight = math.max(0.0, screenSize.height - hudSafeTop - navSafeBottom);

    if (isFixedCanvas) {
      // Dynamic 88% fill calculation based on actual level bounds
      const fillFactor = 0.88;
      final targetWidth = playableWidth * fillFactor;
      final targetHeight = playableHeight * fillFactor;

      final scaleX = targetWidth / actualWidth;
      final scaleY = targetHeight / actualHeight;
      final scale = math.min(scaleX, scaleY);

      // Center the puzzle bounding box cleanly in the playable area
      final offsetX = (screenSize.width - actualWidth * scale) / 2.0;
      final offsetY = hudSafeTop + (playableHeight - actualHeight * scale) / 2.0;

      return PuzzleTransform(
        scale: scale,
        translateX: offsetX - bounds.left * scale,
        translateY: offsetY - bounds.top * scale,
      );
    } else if (isAdaptiveScale) {
      // 1. Calculate available playable area
      // Provide extra safe breathing room specifically requested for Level 11's thicker grid
      final horizontalMargin = levelId == 'level_11' ? 48.0 : 30.0;
      final verticalMargin = levelId == 'level_11' ? 48.0 : 30.0;

      final maxAllowedWidth = math.max(0.0, playableWidth - horizontalMargin * 2);
      final maxAllowedHeight = math.max(0.0, playableHeight - verticalMargin * 2);

      // 3. Determine natural fit scale
      final scaleX = maxAllowedWidth > 0 ? maxAllowedWidth / actualWidth : 1.0;
      final scaleY = maxAllowedHeight > 0 ? maxAllowedHeight / actualHeight : 1.0;
      
      // 4. Adaptive scale: we want a "comfortable" size, not necessarily filling the screen.
      // We cap the maximum scale so small puzzles don't become gigantic.
      final rawScale = math.min(scaleX, scaleY);
      
      final maxScale = 1.1; // Allows a comfortable size for smaller puzzles
      final minScale = 0.3; // Prevent being completely invisible
      final scale = rawScale.clamp(minScale, maxScale);

      // 5. Center the puzzle inside the PLAYABLE area
      final offsetX = (screenSize.width - actualWidth * scale) / 2.0;
      final offsetY = hudSafeTop + (playableHeight - actualHeight * scale) / 2.0;

      return PuzzleTransform(
        scale: scale,
        translateX: offsetX - bounds.left * scale,
        translateY: offsetY - bounds.top * scale,
      );
    } else {
      // Original scaling for levels 13-21
      final padding = math.max(actualWidth, actualHeight) * 0.15 + 40.0;
      
      final paddedWidth = actualWidth + padding * 2;
      final paddedHeight = actualHeight + padding * 2;

      final scaleX = screenSize.width / paddedWidth;
      final scaleY = screenSize.height / paddedHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;

      final offsetX = (screenSize.width - actualWidth * scale) / 2.0;
      final offsetY = (screenSize.height - actualHeight * scale) / 2.0;

      return PuzzleTransform(
        scale: scale,
        translateX: offsetX - bounds.left * scale,
        translateY: offsetY - bounds.top * scale,
      );
    }
  }
}
