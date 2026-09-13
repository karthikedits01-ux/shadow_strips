import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class LevelCompletedOverlay extends StatefulWidget {
  final int nextLevelNum;
  final VoidCallback onNextLevel;
  final VoidCallback onRetry;
  final VoidCallback onLevels;

  const LevelCompletedOverlay({
    super.key,
    required this.nextLevelNum,
    required this.onNextLevel,
    required this.onRetry,
    required this.onLevels,
  });

  @override
  State<LevelCompletedOverlay> createState() => _LevelCompletedOverlayState();
}

class _LevelCompletedOverlayState extends State<LevelCompletedOverlay> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _rotationController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    _confettiController.play();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    
    _entranceController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _rotationController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background Blue with Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Rotating Sunburst Rays
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SunburstPainter(rotation: _rotationController.value * 2 * pi),
                );
              },
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // fall straight down
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
                Colors.cyan
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Title
                const Text(
                  'CLEARED',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Center Icon Card
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 10),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _ArrowsPainter(),
                  ),
                ),

                const Spacer(),

                // Next Game Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onNextLevel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E88E5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Next Game',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                          Text(
                            'Level ${widget.nextLevelNum}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64B5F6),
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
                      onPressed: widget.onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'RETRY',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: widget.onLevels,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text(
                        'LEVELS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final double rotation;

  _SunburstPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = max(size.width, size.height);
    const int numRays = 24;
    const double anglePerRay = (2 * pi) / numRays;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (int i = 0; i < numRays; i++) {
      if (i % 2 == 0) {
        final path = Path();
        path.moveTo(0, 0);
        path.lineTo(radius * cos(i * anglePerRay), radius * sin(i * anglePerRay));
        path.lineTo(radius * cos((i + 1) * anglePerRay), radius * sin((i + 1) * anglePerRay));
        path.close();
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}

class _ArrowsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C1C1E)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final arrowLength = size.height * 0.45;
    final spacing = size.width * 0.2;

    _drawArrow(canvas, Offset(center.dx - spacing, center.dy), arrowLength, true, paint);
    _drawArrow(canvas, Offset(center.dx, center.dy), arrowLength, true, paint);
    _drawArrow(canvas, Offset(center.dx + spacing, center.dy), arrowLength, false, paint);
    
    // Add small yellow highlight like the image
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    // Draw a small yellow highlight on the right arrow
    canvas.drawLine(
       Offset(center.dx + spacing, center.dy),
       Offset(center.dx + spacing, center.dy + 10),
       highlightPaint,
    );
  }

  void _drawArrow(Canvas canvas, Offset center, double length, bool up, Paint paint) {
    final startY = center.dy + (up ? length / 2 : -length / 2);
    final endY = center.dy + (up ? -length / 2 : length / 2);
    
    canvas.drawLine(Offset(center.dx, startY), Offset(center.dx, endY), paint);

    // Arrowhead
    final headSize = 12.0;
    final path = Path();
    if (up) {
      path.moveTo(center.dx - headSize, endY + headSize);
      path.lineTo(center.dx, endY);
      path.lineTo(center.dx + headSize, endY + headSize);
    } else {
      path.moveTo(center.dx - headSize, endY - headSize);
      path.lineTo(center.dx, endY);
      path.lineTo(center.dx + headSize, endY - headSize);
    }
    
    // Switch to fill for the arrowhead
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
