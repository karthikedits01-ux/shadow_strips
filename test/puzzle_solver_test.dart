import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/puzzle_solver.dart';
import 'package:shadow_strips/models/crossing.dart';
import 'package:shadow_strips/models/level_metadata.dart';
import 'package:shadow_strips/models/puzzle_level.dart';
import 'package:shadow_strips/models/strip.dart';

void main() {
  group('PuzzleSolver', () {
    test('isSolvable returns true for valid level', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(
          difficulty: 1,
          stripCount: 2,
          crossingCount: 1,
        ),
        strips: [
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(0, 0)],
            width: 0,
            zIndex: 0,
          ),
          Strip(
            id: 'B',
            points: [Offset(0, 0), Offset(0, 0)],
            width: 0,
            zIndex: 0,
          ),
        ],
        crossings: [Crossing(upperStripId: 'A', lowerStripId: 'B')],
      );

      final graph = DependencyGraph.fromCrossings(
        level.strips,
        level.crossings,
      );
      expect(PuzzleSolver.isSolvable(graph, level.strips.length), isTrue);
    });

    test('getSolutionSequence resolves completely', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(
          difficulty: 1,
          stripCount: 2,
          crossingCount: 1,
        ),
        strips: [
          Strip(
            id: 'B',
            points: [Offset(0, 0), Offset(0, 0)],
            width: 0,
            zIndex: 0,
          ),
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(0, 0)],
            width: 0,
            zIndex: 0,
          ),
        ],
        crossings: [Crossing(upperStripId: 'A', lowerStripId: 'B')],
      );

      final graph = DependencyGraph.fromCrossings(
        level.strips,
        level.crossings,
      );
      final sequence = PuzzleSolver.getSolutionSequence(
        graph,
        level.strips.length,
      );
      expect(sequence, ['A', 'B']);
    });

    test('throws StateError for deadlocked level during solve', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(
          difficulty: 1,
          stripCount: 2,
          crossingCount: 2,
        ),
        strips: [
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(0, 0)],
            width: 0,
            zIndex: 0,
          ),
          Strip(
            id: 'B',
            points: [Offset(0, 0), Offset(0, 0)],
            width: 0,
            zIndex: 0,
          ),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
          Crossing(upperStripId: 'B', lowerStripId: 'A'),
        ],
      );

      final graph = DependencyGraph.fromCrossings(
        level.strips,
        level.crossings,
      );
      expect(PuzzleSolver.isSolvable(graph, level.strips.length), isFalse);
      expect(
        () => PuzzleSolver.getSolutionSequence(graph, level.strips.length),
        throwsStateError,
      );
    });
  });
}
