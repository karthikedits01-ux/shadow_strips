import 'package:flutter/material.dart';
import 'combo_timer_bar.dart';

class HudOverlay extends StatelessWidget {
  final String levelId;
  final int mistakes;
  final VoidCallback onBackTap;
  final VoidCallback onSettingsTap;
  final GlobalKey<ComboTimerBarState>? comboTimerKey;
  final VoidCallback? onTimerPenalty;
  final int comboDurationSeconds;

  const HudOverlay({
    super.key,
    required this.levelId,
    required this.mistakes,
    required this.onBackTap,
    required this.onSettingsTap,
    this.comboTimerKey,
    this.onTimerPenalty,
    this.comboDurationSeconds = 10,
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
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width * 0.45,
                    maxWidth: MediaQuery.of(context).size.width * 0.45,
                  ),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                      if (comboTimerKey != null && onTimerPenalty != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2.0, left: 16, right: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2.0),
                            child: ComboTimerBar(
                              key: comboTimerKey,
                              durationSeconds: comboDurationSeconds,
                              onPenalty: onTimerPenalty!,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Lives / Mistakes indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(maxMistakes, (index) {
                    // Better UX: Lose stars from right to left
                    final isLost = index >= (maxMistakes - mistakes);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                        },
                        child: Icon(
                          Icons.star_rounded,
                          key: ValueKey(isLost),
                          size: 24,
                          color: isLost ? const Color(0xFFE0E0E0) : const Color(0xFF3A3A3A),
                          shadows: isLost ? null : const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
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
