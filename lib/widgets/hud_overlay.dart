import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final String levelId;
  final int mistakes;
  final VoidCallback onBackTap;
  final VoidCallback onSettingsTap;

  const HudOverlay({
    super.key,
    required this.levelId,
    required this.mistakes,
    required this.onBackTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelNum = levelId.replaceAll('level_', '').padLeft(2, '0');
    final maxMistakes = 3;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Back button
            _CircularButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBackTap,
            ),
            
            const Spacer(),
            
            // Center: Level Info and Lives
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Level $levelNum',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Lives / Mistakes indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(maxMistakes, (index) {
                    final isLost = index < mistakes;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isLost ? 8 : 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLost 
                            ? const Color(0xFFE0E0E0) // Greyed out
                            : const Color(0xFF4CAF50), // Green life
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isLost ? null : [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
            
            const Spacer(),

            // Right: Settings button
            _CircularButton(
              icon: Icons.settings_rounded,
              onTap: onSettingsTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircularButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: const Color(0xFF2C3E50), size: 24),
          ),
        ),
      ),
    );
  }
}
