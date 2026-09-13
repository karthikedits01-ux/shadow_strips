
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
  
  bool _isInputLocked = false;
  
  /// Callback when the level is fully completed.
  VoidCallback? onLevelComplete;
  /// Callback when mistakes exceed the allowed limit (default 3).
  VoidCallback? onMistakesExceeded;

  GameState get state => _state;
  bool get isInputLocked => _isInputLocked;

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
    
    _isInputLocked = false;
    notifyListeners();
  }

  /// Handles a tap on a strip. Returns true if the tap was successful and removal started.
  bool handleTap(String stripId) {
    if (_isInputLocked || _state.isComplete || _state.isGameOver) return false;
    
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
    _isInputLocked = true;
    
    final updatedStates = Map<String, StripState>.from(_state.stripStates);
    updatedStates[stripId] = StripState.removing;
    
    _state = _state.copyWith(stripStates: updatedStates);
    
    _hapticService.lightImpact();
    _audioService.playExtractionSuccess();
    
    notifyListeners();
  }

  void _handleLockedTap(String stripId) {
    final level = LevelRepository.getLevel(_state.levelId);
    final maxMistakes = level.metadata.maxMistakes ?? 3;
    
    final newMistakes = _state.mistakes + 1;
    final isGameOver = newMistakes >= maxMistakes;
    
    _state = _state.copyWith(
      mistakes: newMistakes,
      isGameOver: isGameOver,
    );
    
    _hapticService.heavyImpact();
    _audioService.playLockedResistance();
    
    notifyListeners();
    
    if (isGameOver) {
      onMistakesExceeded?.call();
    }
  }

  /// Must be called when the visual extraction animation completes.
  /// Commits the removal transaction and updates graph dependencies.
  void commitRemoval(String stripId) {
    // 1. Remove from logical graph
    _graph.removeNode(stripId);
    
    // 2. Update states
    final updatedStates = Map<String, StripState>.from(_state.stripStates);
    updatedStates[stripId] = StripState.removed;
    
    // 3. Mark newly free nodes
    final freeNodes = _graph.getFreeNodes();
    for (final node in freeNodes) {
      if (updatedStates[node] == StripState.locked) {
        updatedStates[node] = StripState.free;
      }
    }
    
    // 4. Remove from active strips visually
    final updatedActiveStrips = Map<String, Strip>.from(_state.activeStrips);
    updatedActiveStrips.remove(stripId);

    // 5. Check completion
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
    
    _isInputLocked = false;
    notifyListeners();
  }
}
