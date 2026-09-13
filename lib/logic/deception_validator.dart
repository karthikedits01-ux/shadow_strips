import '../models/puzzle_level.dart';
import '../models/crossing.dart';
import 'dependency_graph.dart';
import 'puzzle_solver.dart';

class DeceptionValidator {
  /// Validates the deceptive rules of a puzzle level.
  /// 
  /// Deception rules:
  /// 1. The actual DAG must be completely solvable (checked elsewhere, but re-verified).
  /// 2. The level must not contain deceptive crossings that create a visual paradox 
  ///    (e.g., A -> B deceptive, and B -> A normal, creating an impossible visual cycle).
  /// 3. The metadata must accurately reflect the deceptive crossing count.
  static void validate(PuzzleLevel level) {
    int deceptiveCount = 0;
    final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

    for (final crossing in level.crossings) {
      if (crossing.shadowMode == ShadowMode.deceptive) {
        deceptiveCount++;
      }
    }

    if (level.metadata.deceptiveCrossingCount != deceptiveCount) {
      throw StateError(
          'DeceptionValidator: metadata.deceptiveCrossingCount (${level.metadata.deceptiveCrossingCount}) '
          'does not match actual deceptive crossings ($deceptiveCount)');
    }

    // Verify visual solvability if we were to treat deceptive crossings as actual reversed dependencies.
    // If reversing the deceptive crossings creates a cycle, it means the visual presentation is
    // a cyclic paradox (like a Penrose triangle). The prompt says:
    // "no impossible visual contradiction exists".
    // We can verify this by building a "visual graph" and checking for cycles.
    final visualGraph = _buildVisualGraph(level);
    if (visualGraph.hasCycle()) {
      throw StateError(
          'DeceptionValidator: The deceptive crossings create an impossible visual cycle (paradox).');
    }

    // Finally, ensure the actual graph is mathematically solvable (fairness)
    if (!PuzzleSolver.isSolvable(graph, level.strips.length)) {
      throw StateError('DeceptionValidator: The actual DAG is unsolvable.');
    }
  }

  /// Builds a graph representing what the player *visually* perceives at first glance.
  /// Normal crossings: A -> B
  /// Deceptive crossings: B -> A
  static DependencyGraph _buildVisualGraph(PuzzleLevel level) {
    final visualCrossings = level.crossings.map((c) {
      if (c.shadowMode == ShadowMode.deceptive) {
        // Reverse the dependency visually
        return Crossing(
          upperStripId: c.lowerStripId,
          lowerStripId: c.upperStripId,
          shadowMode: ShadowMode.normal,
        );
      }
      return c;
    }).toList();

    return DependencyGraph.fromCrossings(level.strips, visualCrossings);
  }
}
