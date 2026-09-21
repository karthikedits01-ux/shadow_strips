import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadow_strips/controllers/game_controller.dart';
import 'package:shadow_strips/models/crossing.dart';
import 'package:shadow_strips/models/puzzle_level.dart';
import 'package:shadow_strips/models/level_metadata.dart';
import 'package:shadow_strips/models/strip.dart';
import 'package:shadow_strips/services/audio_service.dart';
import 'package:shadow_strips/services/haptic_service.dart';
import 'package:shadow_strips/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      return null;
    });
  });

  group('GameController', () {
    late GameController controller;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final progressService = ProgressService();
      await progressService.initialize();
      
      controller = GameController(
        audioService: AudioService(progressService),
        hapticService: HapticService(progressService),
      );
    });

    test('loadLevel initializes state correctly', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 1),
        strips: [
          Strip(id: 'A', points: [Offset(0, 0), Offset(0, 0)], width: 0, zIndex: 0),
          Strip(id: 'B', points: [Offset(0, 0), Offset(0, 0)], width: 0, zIndex: 0),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
        ],
      );

      controller.loadLevel(level);

      expect(controller.state.levelId, 'test');
      expect(controller.state.mistakes, 0);
      expect(controller.state.isComplete, isFalse);
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
    });

    test('valid tap locks input and starts removal', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 1),
        strips: [Strip(id: 'A', points: [Offset(0, 0), Offset(100, 0)], width: 10, zIndex: 0)],
        crossings: [],
      );
      controller.loadLevel(level);

      final result = controller.handleTap('A');

      expect(result, isTrue);
      expect(controller.state.stripStates['A'], StripState.removing);
    });

    test('invalid tap increments mistakes and rejects removal', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 1),
        strips: [
          Strip(id: 'A', points: [Offset(0, 0), Offset(100, 0)], width: 10, zIndex: 0),
          Strip(id: 'B', points: [Offset(0, 0), Offset(0, 100)], width: 10, zIndex: 0),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
        ],
      );
      controller.loadLevel(level);

      final result = controller.handleTap('B');

      expect(result, isFalse);
      expect(controller.state.mistakes, 1);
      expect(controller.state.stripStates['B'], StripState.locked);
    });

    test('commitRemoval updates graph, states, and completion', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 1),
        strips: [
          Strip(id: 'A', points: [Offset(0, 0), Offset(100, 0)], width: 10, zIndex: 0),
          Strip(id: 'B', points: [Offset(0, 0), Offset(0, 100)], width: 10, zIndex: 0),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
        ],
      );
      controller.loadLevel(level);

      controller.handleTap('A');
      controller.commitRemoval('A');

      expect(controller.state.stripStates['A'], StripState.removed);
      expect(controller.state.activeStrips.containsKey('A'), isFalse);
      
      // B should now be free
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.isComplete, isFalse);
      
      // Tap B
      controller.handleTap('B');
      controller.commitRemoval('B');
      
      expect(controller.state.isComplete, isTrue);
      expect(controller.state.activeStrips.isEmpty, isTrue);
    });
    
    test('instantly resolves graph so underlying strips become free before animation completes', () {
      final level = PuzzleLevel(
        levelId: 'test',
        metadata: const LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: 1),
        strips: [
          Strip(id: 'A', points: [Offset(0, 0), Offset(100, 0)], width: 10, zIndex: 0),
          Strip(id: 'B', points: [Offset(0, 0), Offset(0, 100)], width: 10, zIndex: 0),
        ],
        crossings: [
          Crossing(upperStripId: 'A', lowerStripId: 'B'),
        ],
      );
      controller.loadLevel(level);

      expect(controller.state.stripStates['B'], StripState.locked);

      controller.handleTap('A'); // A is now removing
      
      expect(controller.state.stripStates['B'], StripState.free); // B is INSTANTLY free
      
      final result = controller.handleTap('B'); // B is free, and should be instantly tappable
      
      expect(result, isTrue);
      expect(controller.state.stripStates['B'], StripState.removing); // both removing concurrently
    });
  });
}
