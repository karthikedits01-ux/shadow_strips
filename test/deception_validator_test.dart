import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/deception_validator.dart';
import 'package:shadow_strips/models/crossing.dart';
import 'package:shadow_strips/models/level_metadata.dart';
import 'package:shadow_strips/models/puzzle_level.dart';
import 'package:shadow_strips/models/strip.dart';

void main() {
  group('DeceptionValidator', () {
    test('validates a fair deceptive level', () {
      final level = PuzzleLevel(
        levelId: 'test_fair_deception',
        metadata: const LevelMetadata(
          difficulty: 5,
          stripCount: 3,
          crossingCount: 2,
          deceptiveCrossingCount: 1, // 1 deceptive crossing
        ),
        strips: [
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(100, 100)],
            width: 10,
            zIndex: 3,
          ),
          Strip(
            id: 'B',
            points: [Offset(0, 100), Offset(100, 0)],
            width: 10,
            zIndex: 2,
          ),
          Strip(
            id: 'C',
            points: [Offset(50, 0), Offset(50, 100)],
            width: 10,
            zIndex: 1,
          ),
        ],
        crossings: [
          // A is physically above B, but deceptively drawn as B above A
          Crossing(
            upperStripId: 'A',
            lowerStripId: 'B',
            shadowMode: ShadowMode.deceptive,
          ),
          // B is physically above C (normal)
          Crossing(upperStripId: 'B', lowerStripId: 'C'),
        ],
      );

      // Should not throw
      expect(() => DeceptionValidator.validate(level), returnsNormally);
    });

    test('throws if metadata count is wrong', () {
      final level = PuzzleLevel(
        levelId: 'test_bad_metadata',
        metadata: const LevelMetadata(
          difficulty: 5,
          stripCount: 3,
          crossingCount: 2,
          deceptiveCrossingCount: 0, // Claim 0, but we have 1
        ),
        strips: [
          Strip(
            id: 'A',
            points: [Offset(0, 0), Offset(100, 100)],
            width: 10,
            zIndex: 3,
          ),
          Strip(
            id: 'B',
            points: [Offset(0, 100), Offset(100, 0)],
            width: 10,
            zIndex: 2,
          ),
        ],
        crossings: [
          Crossing(
            upperStripId: 'A',
            lowerStripId: 'B',
            shadowMode: ShadowMode.deceptive,
          ),
        ],
      );

      expect(
        () => DeceptionValidator.validate(level),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('does not match actual'),
          ),
        ),
      );
    });

    test('throws if deception creates an impossible visual cycle', () {
      final visualCycleLevel = PuzzleLevel(
        levelId: 'test_visual_cycle',
        metadata: const LevelMetadata(
          difficulty: 5,
          stripCount: 3,
          crossingCount: 3,
          deceptiveCrossingCount: 1,
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
          Crossing(upperStripId: 'A', lowerStripId: 'B'), // Visual A->B
          Crossing(upperStripId: 'B', lowerStripId: 'C'), // Visual B->C
          Crossing(
            upperStripId: 'A',
            lowerStripId: 'C',
            shadowMode: ShadowMode.deceptive,
          ), // Visual C->A
        ],
      );

      expect(
        () => DeceptionValidator.validate(visualCycleLevel),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('impossible visual cycle'),
          ),
        ),
      );
    });
  });
}
