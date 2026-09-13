import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/flow_controller.dart';

class HomeScreen extends StatelessWidget {
  final FlowController flowController;

  const HomeScreen({super.key, required this.flowController});

  @override
  Widget build(BuildContext context) {
    final progress = flowController.progressService;
    final currentLevel = progress.currentLevel.replaceAll('level_', '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey/white background
      body: Stack(
        children: [
          // Background shapes
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundShapesPainter(),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Top: Daily Challenge Card
                Center(
                  child: _DailyChallengeCard(
                    onTap: () => flowController.goDaily(),
                  ),
                ),
                
                const Spacer(),
                
                // Middle: Title
                const Center(
                  child: Text(
                    'Arrow Puzzle',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50), // Dark blue/grey
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Bottom: New Game Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calendar Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D), // Orange/Yellow
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: const [
                   BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                   ),
                ]
              ),
              child: Stack(
                children: [
                  // White top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                          CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  // Star inside
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Icon(Icons.star_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Text
            const Text(
              'DAILY CHALLENGE',
              style: TextStyle(
                color: Color(0xFFBBDEFB), // Light blue text
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
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.circular(40),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
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
              'New Game',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Level $level',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
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
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
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
    final color = isSelected ? const Color(0xFF1E88E5) : const Color(0xFF9E9E9E);
    
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

class _BackgroundShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F2F5) // Very light grey
      ..style = PaintingStyle.fill;

    // Draw some large abstract rounded triangles/shapes as seen in background
    // Shape 1: Top left
    final path1 = Path();
    path1.moveTo(-50, 0);
    path1.lineTo(200, 150);
    path1.lineTo(100, 250);
    path1.lineTo(-100, 100);
    path1.close();
    
    // Smooth corners for path1 (simplified approach, actual SVG would be better, but this works for abstract shapes)
    canvas.drawPath(path1, paint);

    // Shape 2: Bottom right
    final path2 = Path();
    path2.moveTo(size.width, size.height - 100);
    path2.lineTo(size.width - 250, size.height - 200);
    path2.lineTo(size.width - 150, size.height - 50);
    path2.lineTo(size.width + 50, size.height + 50);
    path2.close();
    canvas.drawPath(path2, paint);
    
    // Shape 3: Middle right
    final path3 = Path();
    path3.moveTo(size.width + 50, 200);
    path3.lineTo(size.width - 150, 300);
    path3.lineTo(size.width - 50, 450);
    path3.close();
    canvas.drawPath(path3, paint);
    
    // Shape 4: Bottom left
    final path4 = Path();
    path4.moveTo(-50, size.height - 150);
    path4.lineTo(150, size.height - 250);
    path4.lineTo(250, size.height - 100);
    path4.lineTo(50, size.height);
    path4.close();
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
