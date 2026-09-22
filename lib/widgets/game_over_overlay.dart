import 'package:flutter/material.dart';
import '../services/ad_manager.dart';

class GameOverOverlay extends StatefulWidget {
  final VoidCallback onRetry;
  final VoidCallback onGetLives;

  const GameOverOverlay({
    super.key,
    required this.onRetry,
    required this.onGetLives,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  
  bool _isShowingAd = false;

  @override
  void initState() {
    super.initState();
    // Pre-load the ad as soon as the Game Over screen mounts
    AdManager().loadRewardedAd();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleGetLives() {
    if (_isShowingAd) return;
    
    setState(() {
      _isShowingAd = true;
    });

    AdManager().showRewardedAd(
      onRewardEarned: () {
        // Trigger the callback to grant a life
        widget.onGetLives();
      },
      onAdClosed: () {
        if (mounted) {
          setState(() {
            _isShowingAd = false;
          });
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.4 * _fadeAnimation.value),
          child: Center(
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      const Text(
                        'Out of Lives!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Heart Icon with subtle background
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star_rounded,
                                size: 56,
                                color: Color(0xFFFFC107), // Premium Gold Star
                              ),
                            ),
                          ),
                          // Optional cute +1 badge for a "game" feel (purely decorative for now)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Text(
                                '+1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // Primary Button (Bright White)
                      ElevatedButton(
                        onPressed: _isShowingAd ? null : _handleGetLives,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E1E1E), // Dark Charcoal
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: _isShowingAd 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E1E1E))
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Get More Lives',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.play_circle_fill, size: 22),
                              ],
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Secondary Button (Text only, fading into background)
                      TextButton(
                        onPressed: widget.onRetry,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: const Text(
                          'Restart Game',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
      },
    );
  }
}
