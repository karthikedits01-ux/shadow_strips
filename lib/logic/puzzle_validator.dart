import '../models/puzzle_level.dart';
import 'dependency_graph.dart';
import 'puzzle_solver.dart';
import 'deception_validator.dart';
import 'anti_triviality_validator.dart';

/// Validates a level to ensure it meets all production criteria before gameplay.
class PuzzleValidator {
  
  /// Validates the puzzle. Throws a [StateError] if any validation fails.
  /// If it returns normally, the level is valid.
  static void validate(PuzzleLevel level) {
    if (level.strips.isEmpty) {
      throw StateError('Level ${level.levelId} has no strips.');
    }

    // 1. Check for duplicate IDs
    final ids = <String>{};
    for (final strip in level.strips) {
      if (!ids.add(strip.id)) {
        throw StateError('Level ${level.levelId} contains duplicate strip ID: ${strip.id}');
      }
    }

    // 2. Check for invalid geometry (e.g., completely out of logical bounds)
    // Assuming 0,0 to logicalWidth, logicalHeight is the playable area.
    for (final strip in level.strips) {
      bool allOut = true;
      for (final p in strip.points) {
        if (p.dx >= 0 && p.dy >= 0 && p.dx <= level.logicalWidth && p.dy <= level.logicalHeight) {
          allOut = false;
          break;
        }
      }
      if (allOut) {
        throw StateError('Level ${level.levelId} has strip ${strip.id} outside logical bounds.');
      }
    }

    // 3. Check for dependencies referencing nonexistent strips
    for (final crossing in level.crossings) {
      if (!ids.contains(crossing.upperStripId)) {
        throw StateError('Crossing references missing upper strip ID: ${crossing.upperStripId}');
      }
      if (!ids.contains(crossing.lowerStripId)) {
        throw StateError('Crossing references missing lower strip ID: ${crossing.lowerStripId}');
      }
      if (crossing.upperStripId == crossing.lowerStripId) {
         throw StateError('Self-intersecting crossing for ID: ${crossing.upperStripId}');
      }
    }

    // 4. Construct graph and test for cycles
    final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    
    if (graph.hasCycle()) {
      throw StateError('Level ${level.levelId} contains a dependency cycle.');
    }

    // 5. Check if at least one removable strip exists
    if (graph.getFreeNodes().isEmpty) {
      throw StateError('Level ${level.levelId} has no free strips initially. Deadlocked.');
    }

    // 6. Check if it's completely solvable
    if (!PuzzleSolver.isSolvable(graph, level.strips.length)) {
      throw StateError('Level ${level.levelId} is mathematically unsolvable.');
    }

    // 7. Validate Deception Rules
    DeceptionValidator.validate(level);

    // 8. Validate Anti-Triviality
    AntiTrivialityValidator.validate(level);
  }
}
