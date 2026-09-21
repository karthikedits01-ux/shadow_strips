import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/level_repository.dart';
import '../models/strip.dart';

class LevelCompletedOverlay extends StatelessWidget {
  final int nextLevelNum;
  final int starsEarned;
  final VoidCallback onNextLevel;
  final VoidCallback onRetry;
  final VoidCallback onLevels;

  const LevelCompletedOverlay({
    super.key,
    required this.nextLevelNum,
    required this.starsEarned,
    required this.onNextLevel,
    required this.onRetry,
    required this.onLevels,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // We animate a master value from 0.0 to 1.0. 
      // We'll apply different curves manually inside the builder for different elements.
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2500), 
      builder: (context, value, child) {
        final t = value * 2500.0;

        // 1. Fast Background Blur & UI Entrance (0 to 800ms)
        final uiProgress = (t / 800.0).clamp(0.0, 1.0);
        final elasticValue = Curves.elasticOut.transform(uiProgress);
        final uiFade = Curves.easeIn.transform(uiProgress).clamp(0.0, 1.0);
        final uiSlide = Curves.easeOutCubic.transform(uiProgress);
        final mapSlideScale = Curves.easeOutCubic.transform(uiProgress);
        
        final blurValue = Curves.easeOut.transform(uiProgress).clamp(0.0, 1.0);

        // 2. Map Shrink - Sharp Magnetic Snap (1000ms to 1250ms)
        final shrinkProgress = ((t - 1000.0) / 250.0).clamp(0.0, 1.0);
        final mapScale = (1.0 - Curves.easeInExpo.transform(shrinkProgress)).clamp(0.0, 1.0);

        // 3. Ripple Burst (1250ms to 1650ms)
        final isRippleActive = t > 1250.0 && t < 1650.0;
        final rippleProgress = ((t - 1250.0) / 400.0).clamp(0.0, 1.0);
        final rippleScale = 2.0 * Curves.easeOutQuad.transform(rippleProgress);
        final rippleOpacity = (1.0 - rippleProgress).clamp(0.0, 1.0);

        // 4. Checkmark Scale (1250ms to 1750ms)
        final checkProgress = ((t - 1250.0) / 500.0).clamp(0.0, 1.0);
        final checkScale = Curves.elasticOut.transform(checkProgress);

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // True Frosted Glass with Dark Tint
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 15.0 * blurValue,
                    sigmaY: 15.0 * blurValue,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6 * blurValue),
                  ),
                ),
              ),

              // Background is clean, no shockwave.
              
              // Content
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Bouncing Hero Text with Metallic/Neon Glow
                    Transform.scale(
                      scale: elasticValue.clamp(0.0, double.infinity),
                      child: const Text(
                        'CLEARED',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 12.0,
                          shadows: [
                            Shadow(
                              color: Color(0xFFFFD700), // Gold metallic glow
                              blurRadius: 30,
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              color: Colors.white,
                              blurRadius: 10,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Miniature Map Card
                    Transform.scale(
                      scale: 0.8 + (0.2 * mapSlideScale),
                      child: Opacity(
                        opacity: uiFade,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                offset: const Offset(0, 16),
                                blurRadius: 32,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isRippleActive)
                                Transform.scale(
                                  scale: rippleScale,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: rippleOpacity * 0.5),
                                    ),
                                  ),
                                ),
                              if (mapScale > 0)
                                Transform.scale(
                                  scale: mapScale,
                                  child: CustomPaint(
                                    size: const Size(220, 220),
                                    painter: _MiniMapPainter(
                                      strips: LevelRepository.getLevel('level_${nextLevelNum - 1}').strips,
                                    ),
                                  ),
                                ),
                              if (checkScale > 0)
                                Transform.scale(
                                  scale: checkScale,
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 100,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white54,
                                        blurRadius: 24,
                                      ),
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StampingStar(t: t, startTime: 1750.0, duration: 350.0, isEarned: starsEarned >= 1),
                            const SizedBox(width: 16),
                            _StampingStar(t: t, startTime: 1900.0, duration: 350.0, isEarned: starsEarned >= 2),
                            const SizedBox(width: 16),
                            _StampingStar(t: t, startTime: 2050.0, duration: 350.0, isEarned: starsEarned >= 3),
                          ],
                        ),
                      ),
                    ),

                    // Floating Controls
                    Opacity(
                      opacity: uiFade,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1.0 - uiSlide)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Next Game Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                      offset: const Offset(0, 8),
                                      blurRadius: 20,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: ElevatedButton(
                                  onPressed: onNextLevel,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    minimumSize: const Size(double.infinity, 0),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'NEXT GAME',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF1E1E1E),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      Text(
                                        'Level $nextLevelNum',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6E6E73),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Retry and Levels Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: onRetry,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text(
                                    'RETRY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton(
                                  onPressed: onLevels,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text(
                                    'LEVELS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Shockwave painter removed for a cleaner Apple/Tesla minimalist style.

class _MiniMapPainter extends CustomPainter {
  final List<Strip> strips;

  _MiniMapPainter({required this.strips});

  @override
  void paint(Canvas canvas, Size size) {
    if (strips.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final strip in strips) {
      final halfWidth = strip.width / 2;
      for (final point in strip.points) {
        if (point.dx - halfWidth < minX) minX = point.dx - halfWidth;
        if (point.dy - halfWidth < minY) minY = point.dy - halfWidth;
        if (point.dx + halfWidth > maxX) maxX = point.dx + halfWidth;
        if (point.dy + halfWidth > maxY) maxY = point.dy + halfWidth;
      }
    }

    final actualWidth = maxX - minX;
    final actualHeight = maxY - minY;
    
    if (actualWidth <= 0 || actualHeight <= 0) return;

    final padding = 20.0;
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;

    final scaleX = availableWidth / actualWidth;
    final scaleY = availableHeight / actualHeight;
    final scale = math.min(scaleX, scaleY);

    final offsetX = (size.width - actualWidth * scale) / 2.0;
    final offsetY = (size.height - actualHeight * scale) / 2.0;

    canvas.translate(offsetX - minX * scale, offsetY - minY * scale);
    canvas.scale(scale);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0 / scale;

    for (final strip in strips) {
      if (strip.points.isEmpty) continue;
      
      final path = Path();
      path.moveTo(strip.points.first.dx, strip.points.first.dy);
      for (int i = 1; i < strip.points.length; i++) {
        path.lineTo(strip.points[i].dx, strip.points[i].dy);
      }
      
      canvas.drawPath(path, paint);
      
      if (strip.points.length >= 2) {
        final p1 = strip.points[strip.points.length - 2];
        final p2 = strip.points.last;
        final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
        
        final arrowSize = 10.0 / scale;
        
        final arrowPath = Path();
        arrowPath.moveTo(
          p2.dx - arrowSize * math.cos(angle - math.pi / 6),
          p2.dy - arrowSize * math.sin(angle - math.pi / 6),
        );
        arrowPath.lineTo(p2.dx, p2.dy);
        arrowPath.lineTo(
          p2.dx - arrowSize * math.cos(angle + math.pi / 6),
          p2.dy - arrowSize * math.sin(angle + math.pi / 6),
        );
        
        canvas.drawPath(arrowPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    return oldDelegate.strips != strips;
  }
}

class _StampingStar extends StatefulWidget {
  final double t;
  final double startTime;
  final double duration;
  final bool isEarned;

  const _StampingStar({
    required this.t,
    required this.startTime,
    required this.duration,
    required this.isEarned,
  });

  @override
  State<_StampingStar> createState() => _StampingStarState();
}

class _StampingStarState extends State<_StampingStar> {
  bool _hasImpacted = false;

  @override
  void didUpdateWidget(covariant _StampingStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final endTime = widget.startTime + widget.duration;
    if (widget.t >= endTime && oldWidget.t < endTime) {
      if (!_hasImpacted) {
        _hasImpacted = true;
        if (widget.isEarned) {
          HapticFeedback.heavyImpact();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.t < widget.startTime) {
      return const Opacity(
        opacity: 0.0,
        child: SizedBox(width: 48, height: 48),
      );
    }

    final progress = ((widget.t - widget.startTime) / widget.duration).clamp(0.0, 1.0);
    
    final easeValue = Curves.easeOutBack.transform(progress);
    
    final scale = progress < 1.0 
        ? 3.0 - (2.0 * easeValue)
        : 1.0;
        
    final rotation = progress < 1.0
        ? 0.3 * (1.0 - easeValue)
        : 0.0;
        
    final opacity = Curves.easeIn.transform(progress).clamp(0.0, 1.0);

    final color = widget.isEarned ? Colors.white : const Color(0xFF3A3A3A);
    final shadows = widget.isEarned 
        ? const [Shadow(color: Colors.white54, blurRadius: 16)] 
        : const <Shadow>[];

    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.star_rounded,
            color: color,
            size: 48,
            shadows: shadows,
          ),
        ),
      ),
    );
  }
}

