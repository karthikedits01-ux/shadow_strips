
import 'package:flutter/foundation.dart';
import '../logic/dependency_graph.dart';
import '../logic/level_repository.dart';
import '../models/game_state.dart';
import '../models/puzzle_level.dart';
import '../models/strip.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class GameController extends ChangeNotifier {
  final AudioService _audioService;
  final HapticService _hapticService;
  
  late GameState _state;
  late DependencyGraph _graph;
  
  /// Callback when the level is fully completed.
  VoidCallback? onLevelComplete;
  /// Callback when mistakes exceed the allowed limit (default 3).
  VoidCallback? onMistakesExceeded;

  GameState get state => _state;

  // ignore_for_file: prefer_initializing_formals
  GameController({
    required AudioService audioService,
    required HapticService hapticService,
  }) : _audioService = audioService,
       _hapticService = hapticService;

  void loadLevel(PuzzleLevel level) {
    _graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    
    final activeStrips = {for (var strip in level.strips) strip.id: strip};
    final stripStates = <String, StripState>{};
    
    final freeNodes = _graph.getFreeNodes();
    for (final strip in level.strips) {
      stripStates[strip.id] = freeNodes.contains(strip.id) ? StripState.free : StripState.locked;
    }

    final drawOrder = _graph.getTopologicalDrawOrder();

    _state = GameState(
      levelId: level.levelId,
      mistakes: 0,
      isComplete: false,
      isGameOver: false,
      activeStrips: activeStrips,
      stripStates: stripStates,
      drawOrder: drawOrder,
    );
    
    notifyListeners();
  }

  /// Handles a tap on a strip. Returns true if the tap was successful and removal started.
  bool handleTap(String stripId) {
    if (_state.isComplete || _state.isGameOver) return false;
    
    final stripState = _state.stripStates[stripId];
    if (stripState == null || stripState == StripState.removed || stripState == StripState.removing) {
      return false; // Ignore removed/removing
    }

    // 1. Check Z-Axis
    if (stripState == StripState.free) {
      // Clear, start removal (animates, then commits)
      _startRemoval(stripId);
      return true;
    } else {
      // Z-Axis Trap
      _handleLockedTap(stripId);
      return false;
    }
  }

  void _startRemoval(String stripId) {
    // 1. Update states to trigger animation INSTANTLY on the UI thread
    final updatedStates = Map<String, StripState>.from(_state.stripStates);
    updatedStates[stripId] = StripState.removing;
    _state = _state.copyWith(stripStates: updatedStates);
    
    _hapticService.lightImpact();
    _audioService.playExtractionSuccess();
    
    notifyListeners(); // Instant visual feedback

    // 2. Offload complex graph resolution to microtask (Zero-Latency Queueing)
    Future.microtask(() {
      _graph.removeNode(stripId);
      
      final freeNodes = _graph.getFreeNodes();
      bool stateChanged = false;
      final futureStates = Map<String, StripState>.from(_state.stripStates);
      
      for (final node in freeNodes) {
        if (futureStates[node] == StripState.locked) {
          futureStates[node] = StripState.free;
          stateChanged = true;
        }
      }
      
      if (stateChanged) {
        _state = _state.copyWith(stripStates: futureStates);
        notifyListeners(); // Unlock underlying strips instantly for rapid-fire
      }
    });
  }

  void _handleLockedTap(String stripId) {
    _hapticService.heavyImpact();
    _audioService.playLockedResistance();
    
    // Offload score checking and state copying to unblock UI thread
    Future.microtask(() {
      final level = LevelRepository.getLevel(_state.levelId);
      final maxMistakes = level.metadata.maxMistakes ?? 3;
      
      final newMistakes = _state.mistakes + 1;
      final isGameOver = newMistakes >= maxMistakes;
      
      _state = _state.copyWith(
        mistakes: newMistakes,
        isGameOver: isGameOver,
      );
      
      notifyListeners();
      
      if (isGameOver) {
        onMistakesExceeded?.call();
      }
    });
  }

  /// Must be called when the visual extraction animation completes.
  /// Commits the removal transaction and updates graph dependencies.
  void commitRemoval(String stripId) {
    // 1. Update state to fully removed
    final updatedStates = Map<String, StripState>.from(_state.stripStates);
    updatedStates[stripId] = StripState.removed;
    
    // 2. Remove from active strips visually
    final updatedActiveStrips = Map<String, Strip>.from(_state.activeStrips);
    updatedActiveStrips.remove(stripId);

    // 3. Check completion
    final isComplete = updatedActiveStrips.isEmpty;

    _state = _state.copyWith(
      stripStates: updatedStates,
      activeStrips: updatedActiveStrips,
      isComplete: isComplete,
    );
    
    if (isComplete) {
      _audioService.playLevelComplete();
      onLevelComplete?.call();
    }
    
    notifyListeners();
  }
}
