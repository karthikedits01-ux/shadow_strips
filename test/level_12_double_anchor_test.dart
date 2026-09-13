import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';
import 'package:shadow_strips/controllers/game_controller.dart';
import 'package:shadow_strips/models/puzzle_level.dart';
import 'package:shadow_strips/models/strip.dart';
import 'package:shadow_strips/services/audio_service.dart';
import 'package:shadow_strips/services/haptic_service.dart';

class MockAudioService implements AudioService {
  @override Future<void> initialize() async {}
  @override void dispose() {}
  @override Future<void> playExtractionSuccess() async {}
  @override Future<void> playLockedResistance() async {}
  @override Future<void> playLevelComplete() async {}
}

class MockHapticService implements HapticService {
  @override Future<void> lightImpact() async {}
  @override Future<void> heavyImpact() async {}
}

void main() {
  group('Level 12 Double Anchor Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_12');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('1. Exactly 5 strips exist', () {
      expect(level.strips.length, 5);
    });

    test('2-6. Exactly 4 intended dependency edges exist', () {
      expect(level.crossings.length, 4);
      
      bool hasBA = level.crossings.any((c) => c.upperStripId == 'B' && c.lowerStripId == 'A');
      bool hasCA = level.crossings.any((c) => c.upperStripId == 'C' && c.lowerStripId == 'A');
      bool hasAD = level.crossings.any((c) => c.upperStripId == 'A' && c.lowerStripId == 'D');
      bool hasDE = level.crossings.any((c) => c.upperStripId == 'D' && c.lowerStripId == 'E');
      
      expect(hasBA, isTrue, reason: 'B -> A exists');
      expect(hasCA, isTrue, reason: 'C -> A exists');
      expect(hasAD, isTrue, reason: 'A -> D exists');
      expect(hasDE, isTrue, reason: 'D -> E exists');
    });

    test('22. No dependency cycle exists', () {
      expect(graph.hasCycle(), isFalse);
    });

    test('7-11. B and C initially FREE, others locked', () {
      final freeNodes = graph.getFreeNodes();
      expect(freeNodes.length, 2);
      expect(freeNodes.contains('B'), isTrue);
      expect(freeNodes.contains('C'), isTrue);
      
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['A'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('12. Removing B alone does NOT free A', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      expect(controller.state.stripStates['A'], StripState.locked);
    });

    test('13. Removing C alone does NOT free A', () {
      controller.handleTap('C'); controller.commitRemoval('C');
      expect(controller.state.stripStates['A'], StripState.locked);
    });

    test('14. Removing B + C frees A', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      expect(controller.state.stripStates['A'], StripState.free);
    });

    test('15-17. Sequential removals cascade correctly', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      
      controller.handleTap('A'); controller.commitRemoval('A');
      expect(controller.state.stripStates['D'], StripState.free, reason: 'Removing A frees D');
      
      controller.handleTap('D'); controller.commitRemoval('D');
      expect(controller.state.stripStates['E'], StripState.free, reason: 'Removing D frees E');
      
      controller.handleTap('E'); controller.commitRemoval('E');
      expect(controller.state.isComplete, isTrue, reason: 'Removing E completes the level');
    });

    test('18. Valid sequence: B -> C -> A -> D -> E', () {
      final sequence = ['B', 'C', 'A', 'D', 'E'];
      for (final id in sequence) {
        expect(controller.state.stripStates[id], StripState.free, reason: 'Strip \$id should be free');
        controller.handleTap(id);
        controller.commitRemoval(id);
      }
      expect(controller.state.isComplete, isTrue);
    });

    test('19. Valid sequence: C -> B -> A -> D -> E', () {
      final sequence = ['C', 'B', 'A', 'D', 'E'];
      for (final id in sequence) {
        expect(controller.state.stripStates[id], StripState.free, reason: 'Strip \$id should be free');
        controller.handleTap(id);
        controller.commitRemoval(id);
      }
      expect(controller.state.isComplete, isTrue);
    });

    test('20. Invalid locked-strip taps consume mistakes', () {
      expect(controller.state.mistakes, 0);
      controller.handleTap('A');
      expect(controller.state.mistakes, 1);
      expect(controller.state.stripStates['A'], StripState.locked);
    });

    test('21. Reset restores B/C as FREE and A/D/E as LOCKED', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('A'); controller.commitRemoval('A');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['A'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
    });
  });
}
