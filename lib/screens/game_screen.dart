import 'package:flutter/material.dart';
import '../controllers/flow_controller.dart';
import '../logic/level_repository.dart';
import '../models/strip.dart';
import '../rendering/hit_test_engine.dart';
import '../rendering/strip_geometry.dart';
import '../rendering/puzzle_painter.dart';
import '../rendering/puzzle_layout.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/glass_menu.dart';
import '../widgets/completion_transition.dart';
import '../widgets/level_completed_overlay.dart';
import '../widgets/game_over_overlay.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  final FlowController flowController;

  const GameScreen({super.key, required this.flowController});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final Map<String, AnimationController> _removalControllers = {};
  final Map<String, AnimationController> _errorControllers = {};
  
  final Map<String, double> _removalValues = {};
  final Map<String, double> _errorValues = {};

  bool _isMenuOpen = false;

  late final AnimationController _tutorialController;
  late final Animation<double> _tutorialPulse;
  
  final TransformationController _zoomController = TransformationController();
  final ValueNotifier<bool> _isZoomed = ValueNotifier(false);
  
  ui.Image? _noiseTexture;

  @override
  void initState() {
    super.initState();
    _loadNoiseTexture();
    widget.flowController.gameController.addListener(_onGameStateChanged);
    
    _tutorialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _tutorialPulse = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _tutorialController, curve: Curves.easeInOut),
    );
    
    _zoomController.addListener(() {
      final scale = _zoomController.value.getMaxScaleOnAxis();
      final isCurrentlyZoomed = scale > 1.01;
      if (_isZoomed.value != isCurrentlyZoomed) {
        _isZoomed.value = isCurrentlyZoomed;
      }
    });
  }

  Future<void> _loadNoiseTexture() async {
    try {
      final ByteData data = await rootBundle.load('assets/noise.png');
      final bytes = data.buffer.asUint8List();
      final image = await decodeImageFromList(bytes);
      if (mounted) {
        setState(() {
          _noiseTexture = image;
        });
      }
    } catch (e) {
      debugPrint("Failed to load noise texture: $e");
    }
  }

  @override
  void dispose() {
    widget.flowController.gameController.removeListener(_onGameStateChanged);
    for (final controller in _removalControllers.values) {
      controller.dispose();
    }
    for (final controller in _errorControllers.values) {
      controller.dispose();
    }
    _tutorialController.dispose();
    _zoomController.dispose();
    _isZoomed.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    final state = widget.flowController.gameController.state;

    // Cleanup controllers for strips that are no longer in 'removing' or 'locked' states (e.g. on reset)
    final removingKeys = _removalControllers.keys.toList();
    for (final id in removingKeys) {
      if (state.stripStates[id] != StripState.removing) {
        _removalControllers[id]?.dispose();
        _removalControllers.remove(id);
        _removalValues.remove(id);
      }
    }
    
    final errorKeys = _errorControllers.keys.toList();
    for (final id in errorKeys) {
      if (state.stripStates[id] != StripState.locked) {
        _errorControllers[id]?.dispose();
        _errorControllers.remove(id);
        _errorValues.remove(id);
      }
    }

    // Check for removing states and start animations
    for (final entry in state.stripStates.entries) {
      final stripId = entry.key;
      final stripState = entry.value;

      if (stripState == StripState.removing && !_removalControllers.containsKey(stripId)) {
        _startRemovalAnimation(stripId);
      }
    }
    
    setState(() {}); // Trigger rebuild to reflect logical state changes immediately
  }

  void _startRemovalAnimation(String stripId) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Smooth slithering 600ms
    );

    _removalControllers[stripId] = controller;

    controller.addListener(() {
      setState(() {
        _removalValues[stripId] = Curves.easeInOutCubic.transform(controller.value);
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.flowController.gameController.commitRemoval(stripId);
        // Clean up controller
        _removalControllers[stripId]?.dispose();
        _removalControllers.remove(stripId);
      }
    });

    controller.forward();
  }

  void _triggerErrorAnimation(String stripId) {
    if (_errorControllers.containsKey(stripId)) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _errorControllers[stripId] = controller;

    controller.addListener(() {
      setState(() {
        _errorValues[stripId] = controller.value;
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _errorControllers[stripId]?.dispose();
        _errorControllers.remove(stripId);
        _errorValues.remove(stripId);
      }
    });

    controller.forward();
  }

  void _handleTapDown(TapDownDetails details, Size size, double safeTop, double safeBottom) {
    if (_isMenuOpen) {
      setState(() => _isMenuOpen = false);
      return;
    }

    final gameController = widget.flowController.gameController;
    final level = LevelRepository.getLevel(gameController.state.levelId);
    
    final bounds = StripGeometry.getLevelBounds(level.strips);
    
    final logicalTap = HitTestEngine.physicalToLogical(
      details.localPosition, 
      size, 
      bounds,
      level.levelId,
      safeTop,
      safeBottom,
    );

    final transform = PuzzleLayout.calculateTransform(
      screenSize: size,
      bounds: bounds,
      levelId: level.levelId,
      safeAreaTop: safeTop,
      safeAreaBottom: safeBottom,
    );

    final zoomScale = _zoomController.value.getMaxScaleOnAxis();
    final effectiveScale = transform.scale * zoomScale;

    final hitStripId = HitTestEngine.hitTest(
      logicalTap, 
      gameController.state,
      physicalScale: effectiveScale,
    );

    if (hitStripId != null) {
      final success = gameController.handleTap(hitStripId);
      if (!success && !gameController.isInputLocked) {
        // Only trigger error if not locked out completely by another animation
        final state = gameController.state.stripStates[hitStripId];
        if (state == StripState.locked) {
           _triggerErrorAnimation(hitStripId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      body: ListenableBuilder(
        listenable: widget.flowController.gameController,
        builder: (context, _) {
          final state = widget.flowController.gameController.state;
          final level = LevelRepository.getLevel(state.levelId);
          final currentNum = int.tryParse(state.levelId.split('_').last) ?? 1;

          final isLevel1 = state.levelId == 'level_1';
          if (isLevel1 && !state.isComplete && !_tutorialController.isAnimating) {
            _tutorialController.repeat(reverse: true);
          } else if ((!isLevel1 || state.isComplete) && _tutorialController.isAnimating) {
            _tutorialController.stop();
          }

          return Stack(
            children: [
              // 1. Puzzle Board with Transition
              Positioned.fill(
                child: CompletionTransition(
                  isComplete: state.isComplete,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      final mediaQuery = MediaQuery.of(context);
                      final safeTop = mediaQuery.padding.top;
                      final safeBottom = mediaQuery.padding.bottom;
                      
                      return InteractiveViewer(
                        transformationController: _zoomController,
                        minScale: 1.0,
                        maxScale: 2.0, // Strictly max 2x zoom
                        clipBehavior: Clip.none,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) => _handleTapDown(details, size, safeTop, safeBottom),
                          child: AnimatedBuilder(
                            animation: _tutorialController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: size,
                                painter: PuzzlePainter(
                                  state: state,
                                  level: level,
                                  logicalWidth: level.logicalWidth,
                                  logicalHeight: level.logicalHeight,
                                  removalAnimations: _removalValues,
                                  errorAnimations: _errorValues,
                                  tutorialPulseValue: isLevel1 ? _tutorialPulse.value : 0.0,
                                  noiseTexture: _noiseTexture,
                                  safeAreaTop: safeTop,
                                  safeAreaBottom: safeBottom,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Minimal HUD Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HudOverlay(
                  levelId: state.levelId,
                  mistakes: state.mistakes,
                  onBackTap: () {
                    widget.flowController.goHome();
                  },
                  onSettingsTap: () {
                    widget.flowController.goSettings();
                  },
                ),
              ),

              // 3. Reset Zoom Button
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 100,
                right: 20,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isZoomed,
                  builder: (context, isZoomed, child) {
                    if (!isZoomed) return const SizedBox.shrink();
                    return FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black87,
                      child: const Icon(Icons.zoom_out_map, color: Colors.white),
                      onPressed: () {
                        // Reset zoom
                        _zoomController.value = Matrix4.identity();
                      },
                    );
                  },
                ),
              ),

              // 4. Glass Menu
              if (_isMenuOpen)
                Positioned.fill(
                  child: GlassMenu(
                    onResume: () => setState(() => _isMenuOpen = false),
                    onHome: () {
                      setState(() => _isMenuOpen = false);
                      widget.flowController.goHome();
                    },
                    onLevels: () {
                      setState(() => _isMenuOpen = false);
                      widget.flowController.goLevels();
                    },
                    onDaily: () {
                      setState(() => _isMenuOpen = false);
                      widget.flowController.goDaily();
                    },
                    onSettings: () {
                      setState(() => _isMenuOpen = false);
                      widget.flowController.goSettings();
                    },
                  ),
                ),
                
              // 4. Level Completed Overlay
              if (state.isComplete)
                Positioned.fill(
                  child: LevelCompletedOverlay(
                    nextLevelNum: currentNum + 1,
                    onNextLevel: () {
                      widget.flowController.loadNextLevel();
                    },
                    onRetry: () {
                      widget.flowController.resetCurrentLevel();
                    },
                    onLevels: () {
                      widget.flowController.goLevels();
                    },
                  ),
                ),
                
              // 5. Game Over Overlay
              if (state.isGameOver)
                Positioned.fill(
                  child: GameOverOverlay(
                    onRetry: () {
                      widget.flowController.resetCurrentLevel();
                    },
                    onMain: () {
                      widget.flowController.goHome();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
