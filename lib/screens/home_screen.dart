import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/flow_controller.dart';

class HomeScreen extends StatelessWidget {
  final FlowController flowController;

  const HomeScreen({super.key, required this.flowController});

  @override
  Widget build(BuildContext context) {
    final progress = flowController.progressService;
    final currentLevel = progress.currentLevel.replaceAll('level_', '');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.2, -0.4),
              radius: 1.5,
              colors: [Color(0xFF2A2D34), Color(0xFF0D0E12)],
            ),
          ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StripsBackgroundPainter(),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                
                // Top: Daily Challenge Card
                Center(
                  child: _DailyChallengeCard(
                    onTap: () => flowController.goDaily(),
                  ),
                ),
                
                const Spacer(),
                
                // Middle: Title
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.orbitron(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            blurRadius: 15,
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      children: const [
                        TextSpan(
                          text: 'Shadow ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Strips',
                          style: TextStyle(color: Color(0xFF00E5FF)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Bottom: New Game Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _NewGameButton(
                    level: currentLevel,
                    onTap: () => flowController.resumeGame(),
                  ),
                ),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            flowController.goDaily();
          } else if (index == 2) {
            flowController.goSettings(); // Assuming 'Me' goes to settings for now
          }
        },
      ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DailyChallengeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = DateFormat('MMMM d').format(now);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.0),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white24, Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(22.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Calendar Icon
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      size: 32,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Text
                  const Text(
                    'DAILY CHALLENGE',
                    style: TextStyle(
                      color: Colors.white, // Pure White
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Play Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2), // Semi-transparent white
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Play',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewGameButton extends StatelessWidget {
  final String level;
  final VoidCallback onTap;

  const _NewGameButton({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64.0,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.circular(40),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF121212),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              color: Color(0xFF121212),
              size: 28,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Game',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Color(0xFF121212),
                  ),
                ),
                Text(
                  'Level $level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF121212),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavBarItem(
            icon: Icons.home_rounded,
            label: 'Main',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavBarItem(
            icon: Icons.calendar_month_rounded,
            label: 'Daily',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavBarItem(
            icon: Icons.person_rounded,
            label: 'Me',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : Colors.white38;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
      
    // Draw diagonal strips for texture
    for (double i = -size.height; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    for (double i = -size.height + 30; i < size.width; i += 120) {
      paint.strokeWidth = 8.0;
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
      paint.strokeWidth = 2.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

