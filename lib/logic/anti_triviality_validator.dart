import '../models/puzzle_level.dart';
import '../models/crossing.dart';
import 'dependency_graph.dart';

class AntiTrivialityValidator {
  /// Validates that a level is not trivial.
  ///
  /// A trivial level is defined as:
  /// - A level with > 3 strips that has a strictly linear dependency chain 
  ///   (branching factor == 1) and no deceptive crossings.
  /// - A level where every step has only 1 free strip.
  static void validate(PuzzleLevel level) {
    if (level.strips.length <= 3) {
      // Very small introductory levels are allowed to be trivial.
      return;
    }

    // Check if there are any deceptive crossings. If yes, it's not trivial.
    final hasDeception = level.crossings.any((c) => c.shadowMode == ShadowMode.deceptive);
    if (hasDeception) return;

    // Check max concurrent free strips during the solve path
    int maxBranching = 0;
    
    // Simulate solving to find max concurrent options
    final simGraph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    
    while (!simGraph.isEmpty) {
      final freeNodes = simGraph.getFreeNodes();
      if (freeNodes.isEmpty) break; // Deadlock, handled elsewhere
      
      if (freeNodes.length > maxBranching) {
        maxBranching = freeNodes.length;
      }
      
      // Remove all free nodes (greedy solve step to find parallel tracks)
      for (final node in freeNodes) {
        simGraph.removeNode(node);
      }
    }

    if (maxBranching <= 1) {
      throw StateError(
          'AntiTrivialityValidator: Level ${level.levelId} is trivial. '
          'It has a strictly linear solution path with no branching or deception.');
    }
  }
}
