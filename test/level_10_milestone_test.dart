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
  group('Level 10 Milestone Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_10');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('1. Exactly 8 strips exist', () {
      expect(level.strips.length, 8);
    });

    test('2. Exactly 8 intended dependency edges exist', () {
      expect(level.crossings.length, 8);
    });

    test('4. No dependency cycle exists', () {
      expect(graph.hasCycle(), isFalse);
    });

    test('5. Exactly 4 strips are initially FREE', () {
      final freeNodes = graph.getFreeNodes();
      expect(freeNodes.length, 4);
      expect(freeNodes.contains('A'), isTrue);
      expect(freeNodes.contains('B'), isTrue);
      expect(freeNodes.contains('C'), isTrue);
      expect(freeNodes.contains('G'), isTrue);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['G'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
      expect(controller.state.stripStates['H'], StripState.locked);
    });

    test('10. Removing A alone does not free D', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      expect(controller.state.stripStates['D'], StripState.locked);
    });

    test('11. Removing B alone does not free D', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      expect(controller.state.stripStates['D'], StripState.locked);
    });

    test('12. Removing A+B frees D', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      expect(controller.state.stripStates['D'], StripState.free);
    });

    test('13. Removing C frees E', () {
      controller.handleTap('C'); controller.commitRemoval('C');
      expect(controller.state.stripStates['E'], StripState.free);
    });

    test('14-17. Removing D+E+G frees F', () {
      // Free D
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      // Free E
      controller.handleTap('C'); controller.commitRemoval('C');
      
      // Remove D alone does not free F
      controller.handleTap('D'); controller.commitRemoval('D');
      expect(controller.state.stripStates['F'], StripState.locked);
      
      // Remove E does not free F
      controller.handleTap('E'); controller.commitRemoval('E');
      expect(controller.state.stripStates['F'], StripState.locked);
      
      // Remove G frees F
      controller.handleTap('G'); controller.commitRemoval('G');
      expect(controller.state.stripStates['F'], StripState.free);
    });

    test('18-20. Removing F+G frees H', () {
      // Clear board down to F and G
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      // G alone does not free H
      controller.handleTap('G'); controller.commitRemoval('G');
      expect(controller.state.stripStates['H'], StripState.locked);
      
      // F frees H
      controller.handleTap('F'); controller.commitRemoval('F');
      expect(controller.state.stripStates['H'], StripState.free);
    });

    test('21a. Valid sequence 1: A B C G D E F H', () {
      final sequence = ['A', 'B', 'C', 'G', 'D', 'E', 'F', 'H'];
      for (final id in sequence) {
        expect(controller.state.stripStates[id], StripState.free, reason: 'Strip \$id should be free');
        controller.handleTap(id);
        controller.commitRemoval(id);
      }
      expect(controller.state.isComplete, isTrue);
    });

    test('21b. Valid sequence 2: G C A B E D F H', () {
      final sequence = ['G', 'C', 'A', 'B', 'E', 'D', 'F', 'H'];
      for (final id in sequence) {
        expect(controller.state.stripStates[id], StripState.free, reason: 'Strip \$id should be free');
        controller.handleTap(id);
        controller.commitRemoval(id);
      }
      expect(controller.state.isComplete, isTrue);
    });

    test('21c. Valid sequence 3: B A D C E G F H', () {
      final sequence = ['B', 'A', 'D', 'C', 'E', 'G', 'F', 'H'];
      for (final id in sequence) {
        expect(controller.state.stripStates[id], StripState.free, reason: 'Strip \$id should be free');
        controller.handleTap(id);
        controller.commitRemoval(id);
      }
      expect(controller.state.isComplete, isTrue);
    });

    test('22. Invalid locked taps are rejected', () {
      expect(controller.state.mistakes, 0);
      controller.handleTap('H');
      expect(controller.state.mistakes, 1);
      expect(controller.state.stripStates['H'], StripState.locked);
    });

    test('23. Reset restores the original state', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('D'); controller.commitRemoval('D');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['G'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
      expect(controller.state.stripStates['H'], StripState.locked);
    });
  });
}
