import 'package:equatable/equatable.dart';

import 'strip.dart';

/// The overall state of the game session.
class GameState extends Equatable {
  final String levelId;
  final int mistakes;
  final bool isComplete;
  final bool isGameOver;
  
  /// The strips that remain active on the board (not yet extracted).
  final Map<String, Strip> activeStrips;
  
  /// The specific state of each active strip.
  final Map<String, StripState> stripStates;
  
  /// The topological draw order (bottom-to-top) to ensure visual truth.
  final List<String> drawOrder;
  
  const GameState({
    required this.levelId,
    required this.mistakes,
    required this.isComplete,
    required this.isGameOver,
    required this.activeStrips,
    required this.stripStates,
    required this.drawOrder,
  });

  GameState copyWith({
    String? levelId,
    int? mistakes,
    bool? isComplete,
    bool? isGameOver,
    Map<String, Strip>? activeStrips,
    Map<String, StripState>? stripStates,
    List<String>? drawOrder,
  }) {
    return GameState(
      levelId: levelId ?? this.levelId,
      mistakes: mistakes ?? this.mistakes,
      isComplete: isComplete ?? this.isComplete,
      isGameOver: isGameOver ?? this.isGameOver,
      activeStrips: activeStrips ?? this.activeStrips,
      stripStates: stripStates ?? this.stripStates,
      drawOrder: drawOrder ?? this.drawOrder,
    );
  }

  @override
  List<Object?> get props => [
        levelId,
        mistakes,
        isComplete,
        isGameOver,
        activeStrips,
        stripStates,
        drawOrder,
      ];
}
