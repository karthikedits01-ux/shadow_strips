import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/anti_triviality_validator.dart';
import 'package:shadow_strips/models/crossing.dart';
import 'package:shadow_strips/models/level_metadata.dart';
import 'package:shadow_strips/models/puzzle_level.dart';
import 'package:shadow_strips/models/strip.dart';

void main() {
  group('AntiTrivialityValidator', () {
    test('accepts small tutorial levels even if trivial', () {
      final level = PuzzleLevel(
        levelId: 'tutorial',
        metadata: const LevelMetadata(
          difficulty: 1,
          stripCount: 3,
          crossingCount: 2,
        ),
        strips: [
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 3,
          ),
          Strip(
            id: 'B',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 2,
          ),
          Strip(
            id: 'C',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 1,
          ),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
          Crossing(upperStripId: 'B', lowerStripId: 'C'),
        ],
      );

      expect(() => AntiTrivialityValidator.validate(level), returnsNormally);
    });

    test('rejects larger levels that are strictly linear', () {
      final level = PuzzleLevel(
        levelId: 'linear_bad',
        metadata: const LevelMetadata(
          difficulty: 1,
          stripCount: 4,
          crossingCount: 3,
        ),
        strips: [
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 4,
          ),
          Strip(
            id: 'B',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 3,
          ),
          Strip(
            id: 'C',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 2,
          ),
          Strip(
            id: 'D',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 1,
          ),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
          Crossing(upperStripId: 'B', lowerStripId: 'C'),
          Crossing(upperStripId: 'C', lowerStripId: 'D'),
        ],
      );

      expect(
        () => AntiTrivialityValidator.validate(level),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('strictly linear'),
          ),
        ),
      );
    });

    test('accepts levels with branching factor > 1', () {
      final level = PuzzleLevel(
        levelId: 'branching_good',
        metadata: const LevelMetadata(
          difficulty: 1,
          stripCount: 4,
          crossingCount: 3,
        ),
        strips: [
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 4,
          ),
          Strip(
            id: 'B',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 3,
          ),
          Strip(
            id: 'C',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 2,
          ),
          Strip(
            id: 'D',
            points: [Offset(0, 0), Offset(10, 10)],
            width: 1,
            zIndex: 1,
          ),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
          Crossing(upperStripId: 'A', lowerStripId: 'C'),
          Crossing(upperStripId: 'B', lowerStripId: 'D'),
          Crossing(upperStripId: 'C', lowerStripId: 'D'),
        ],
      );

      // Max branching is 2 (B and C are both free after A is removed)
      expect(() => AntiTrivialityValidator.validate(level), returnsNormally);
    });
  });
}
