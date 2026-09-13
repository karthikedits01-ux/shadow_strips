import 'package:equatable/equatable.dart';

import 'strip.dart';
import 'crossing.dart';
import 'shadow_config.dart';
import 'level_metadata.dart';

/// A complete, static definition of a puzzle level.
///
/// This serves as the blueprint for creating a playable game state.
/// Contains the layout of strips and their dependencies.
class PuzzleLevel extends Equatable {
  final String levelId;
  final List<Strip> strips;
  final List<Crossing> crossings;
  
  // Coordinate space definition for independence from screen size
  final double logicalWidth;
  final double logicalHeight;

  final ShadowConfig shadowConfig;
  final LevelMetadata metadata;

  const PuzzleLevel({
    required this.levelId,
    required this.metadata,
    required this.strips,
    required this.crossings,
    this.shadowConfig = const ShadowConfig(),
    this.logicalWidth = 1000.0,
    this.logicalHeight = 1600.0,
  });

  PuzzleLevel copyWith({
    String? levelId,
    LevelMetadata? metadata,
    List<Strip>? strips,
    List<Crossing>? crossings,
    ShadowConfig? shadowConfig,
    double? logicalWidth,
    double? logicalHeight,
  }) {
    return PuzzleLevel(
      levelId: levelId ?? this.levelId,
      metadata: metadata ?? this.metadata,
      strips: strips ?? this.strips,
      crossings: crossings ?? this.crossings,
      shadowConfig: shadowConfig ?? this.shadowConfig,
      logicalWidth: logicalWidth ?? this.logicalWidth,
      logicalHeight: logicalHeight ?? this.logicalHeight,
    );
  }

  @override
  List<Object?> get props => [
        levelId,
        strips,
        crossings,
        logicalWidth,
        logicalHeight,
        shadowConfig,
        metadata,
      ];
}
