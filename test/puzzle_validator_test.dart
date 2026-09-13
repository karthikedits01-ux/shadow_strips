import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/puzzle_validator.dart';
import 'package:shadow_strips/models/crossing.dart';
import 'package:shadow_strips/models/puzzle_level.dart';
import 'package:shadow_strips/models/level_metadata.dart';
import 'package:shadow_strips/models/strip.dart';

void main() {
  group('PuzzleValidator', () {
    const defaultStrip = Strip(
      id: 'A',
      points: [Offset(10, 10), Offset(50, 50)],
      width: 10,
      zIndex: 1,
    );

    test('validates successful level', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 1),
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

      expect(() => PuzzleValidator.validate(level), returnsNormally);
    });

    test('throws on duplicate strip ID', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 0),
        strips: [
          Strip(
            id: 'A',
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
        crossings: [],
      );

      expect(() => PuzzleValidator.validate(level), throwsStateError);
    });

    test('throws on cyclic dependency', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 2),
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

      expect(() => PuzzleValidator.validate(level), throwsStateError);
    });

    test('throws on out of bounds strip', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: LevelMetadata(difficulty: 1, stripCount: 1, crossingCount: 0),
        logicalWidth: 1000,
        logicalHeight: 1600,
        strips: [
          defaultStrip.copyWith(
            points: [Offset(2000, 2000), Offset(2050, 2050)],
          ), // Outside
        ],
        crossings: [],
      );

      expect(() => PuzzleValidator.validate(level), throwsStateError);
    });
  });
}

extension StripCopy on Strip {
  Strip copyWith({String? id, List<Offset>? points}) {
    return Strip(
      id: id ?? this.id,
      points: points ?? this.points,
      width: width,
      zIndex: zIndex,
    );
  }
}
