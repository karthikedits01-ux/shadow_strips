
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';
import 'package:shadow_strips/models/puzzle_level.dart';
import 'package:shadow_strips/models/strip.dart';
import 'package:shadow_strips/controllers/game_controller.dart';
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
  group('Level 1 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_1');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isFalse);
    });

    test('Test 2: Only A is initially free', () {
      final freeNodes = graph.getFreeNodes();
      expect(freeNodes.length, 1);
      expect(freeNodes.first, 'A');
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
    });

    test('Test 3: Attempting B before A does not remove B', () {
      final success = controller.handleTap('B'); 
      expect(success, isFalse);
      expect(controller.state.mistakes, 1);
      expect(controller.state.stripStates['B'], StripState.locked);
    });

    test('Test 4: Remove A -> B becomes free', () {
      final success = controller.handleTap('A');
      expect(success, isTrue);
      expect(controller.state.stripStates['A'], StripState.removing);
      
      controller.commitRemoval('A');
      
      expect(controller.state.stripStates['A'], StripState.removed);
      expect(controller.state.stripStates['B'], StripState.free);
    });

    test('Test 5: Remove B -> triggers completion', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      
      final success = controller.handleTap('B');
      expect(success, isTrue);
      controller.commitRemoval('B');
      
      expect(controller.state.stripStates['B'], StripState.removed);
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 6: Reset restores graph state', () {
      // Partial progress
      controller.handleTap('A');
      controller.commitRemoval('A');
      expect(controller.state.stripStates['B'], StripState.free);
      
      // Simulate reset by loading level again
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.mistakes, 0);
    });

    test('Test 9: Three invalid attempts produce failure state', () {
      controller.handleTap('B'); // 1
      controller.handleTap('B'); // 2
      controller.handleTap('B'); // 3
      
      expect(controller.state.mistakes, 3);
      expect(controller.state.isGameOver, isTrue);
    });

    test('Test 10: No dependency cycle exists', () {
      expect(graph.hasCycle(), isFalse);
    });
  });

  group('Level 2 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_2');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 3);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isFalse);
      expect(graph.isFree('C'), isFalse);
    });

    test('Test 2: A is initially free, others locked', () {
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 3: Attempting B before A fails', () {
      final success = controller.handleTap('B'); 
      expect(success, isFalse);
      expect(controller.state.stripStates['B'], StripState.locked);
    });

    test('Test 4: Attempting C before B fails', () {
      final success = controller.handleTap('C'); 
      expect(success, isFalse);
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 5: Remove A -> B becomes free', () {
      expect(controller.handleTap('A'), isTrue);
      controller.commitRemoval('A');
      
      expect(controller.state.stripStates['A'], StripState.removed);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 6: Remove B -> C becomes free', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      
      expect(controller.handleTap('B'), isTrue);
      controller.commitRemoval('B');
      
      expect(controller.state.stripStates['B'], StripState.removed);
      expect(controller.state.stripStates['C'], StripState.free);
    });

    test('Test 7: Remove C -> triggers completion', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      controller.handleTap('B');
      controller.commitRemoval('B');
      
      expect(controller.handleTap('C'), isTrue);
      controller.commitRemoval('C');
      
      expect(controller.state.stripStates['C'], StripState.removed);
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 8: Reset restores graph state', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      controller.handleTap('B');
      controller.commitRemoval('B');
      
      // Simulate reset by loading level again
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['C'], StripState.locked);
    });
  });

  group('Level 3 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_3');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 4);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isFalse);
      expect(graph.isFree('C'), isFalse);
      expect(graph.isFree('D'), isFalse);
      expect(graph.hasCycle(), isFalse);
    });

    test('Test 2: A is initially free, others locked', () {
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
    });

    test('Test 3: Attempting B, C, D before A fails', () {
      expect(controller.handleTap('B'), isFalse);
      expect(controller.handleTap('C'), isFalse);
      expect(controller.handleTap('D'), isFalse);
    });

    test('Test 4: Remove A -> B becomes free', () {
      expect(controller.handleTap('A'), isTrue);
      controller.commitRemoval('A');
      
      expect(controller.state.stripStates['A'], StripState.removed);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
    });

    test('Test 5: Remove B -> C and D become free', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      
      expect(controller.handleTap('B'), isTrue);
      controller.commitRemoval('B');
      
      expect(controller.state.stripStates['B'], StripState.removed);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
    });

    test('Test 6: Valid sequence A -> B -> C -> D completes level', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      controller.handleTap('B');
      controller.commitRemoval('B');
      
      expect(controller.handleTap('C'), isTrue);
      controller.commitRemoval('C');
      expect(controller.state.stripStates['C'], StripState.removed);
      expect(controller.state.isComplete, isFalse);
      
      expect(controller.handleTap('D'), isTrue);
      controller.commitRemoval('D');
      expect(controller.state.stripStates['D'], StripState.removed);
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 7: Valid sequence A -> B -> D -> C completes level', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      controller.handleTap('B');
      controller.commitRemoval('B');
      
      expect(controller.handleTap('D'), isTrue);
      controller.commitRemoval('D');
      expect(controller.state.stripStates['D'], StripState.removed);
      expect(controller.state.isComplete, isFalse);
      
      expect(controller.handleTap('C'), isTrue);
      controller.commitRemoval('C');
      expect(controller.state.stripStates['C'], StripState.removed);
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 8: Reset restores graph state', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      controller.handleTap('B');
      controller.commitRemoval('B');
      controller.handleTap('C');
      controller.commitRemoval('C');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
    });
  });

  group('Level 4 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_4');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 4);
      expect(graph.isFree('C'), isTrue);
      expect(graph.isFree('A'), isFalse);
      expect(graph.isFree('B'), isFalse);
      expect(graph.isFree('D'), isFalse);
      expect(graph.hasCycle(), isFalse);
    });

    test('Test 2: C is initially free, others locked', () {
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['A'], StripState.locked);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
    });

    test('Test 3: Attempting A, B, D before C fails', () {
      expect(controller.handleTap('A'), isFalse);
      expect(controller.handleTap('B'), isFalse);
      expect(controller.handleTap('D'), isFalse);
    });

    test('Test 4: Remove C -> A and D become free, B remains locked', () {
      expect(controller.handleTap('C'), isTrue);
      controller.commitRemoval('C');
      
      expect(controller.state.stripStates['C'], StripState.removed);
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
    });

    test('Test 5: Remove C then A -> B becomes free', () {
      controller.handleTap('C');
      controller.commitRemoval('C');
      
      expect(controller.handleTap('A'), isTrue);
      controller.commitRemoval('A');
      
      expect(controller.state.stripStates['A'], StripState.removed);
      expect(controller.state.stripStates['B'], StripState.free);
    });

    test('Test 6: Valid sequence C -> A -> B -> D completes level', () {
      controller.handleTap('C');
      controller.commitRemoval('C');
      controller.handleTap('A');
      controller.commitRemoval('A');
      controller.handleTap('B');
      controller.commitRemoval('B');
      
      expect(controller.handleTap('D'), isTrue);
      controller.commitRemoval('D');
      expect(controller.state.stripStates['D'], StripState.removed);
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 7: Valid sequence C -> D -> A -> B completes level', () {
      controller.handleTap('C');
      controller.commitRemoval('C');
      controller.handleTap('D');
      controller.commitRemoval('D');
      controller.handleTap('A');
      controller.commitRemoval('A');
      
      expect(controller.handleTap('B'), isTrue);
      controller.commitRemoval('B');
      expect(controller.state.stripStates['B'], StripState.removed);
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 8: Reset restores graph state', () {
      controller.handleTap('C');
      controller.commitRemoval('C');
      controller.handleTap('A');
      controller.commitRemoval('A');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['A'], StripState.locked);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
    });
  });

  group('Level 5 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_5');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 5);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isFalse);
      expect(graph.isFree('C'), isFalse);
      expect(graph.isFree('D'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.hasCycle(), isFalse);
    });

    test('Test 2: Only A is initially free', () {
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('Test 3: Attempting B, C, D, E before A fails', () {
      expect(controller.handleTap('B'), isFalse);
      expect(controller.handleTap('C'), isFalse);
      expect(controller.handleTap('D'), isFalse);
      expect(controller.handleTap('E'), isFalse);
    });

    test('Test 4: Remove A -> B becomes free', () {
      expect(controller.handleTap('A'), isTrue);
      controller.commitRemoval('A');
      
      expect(controller.state.stripStates['A'], StripState.removed);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('Test 5: Remove A, B -> C and D become free', () {
      controller.handleTap('A');
      controller.commitRemoval('A');
      
      expect(controller.handleTap('B'), isTrue);
      controller.commitRemoval('B');
      
      expect(controller.state.stripStates['B'], StripState.removed);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('Test 6: Remove C before D does NOT free E', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      
      expect(controller.handleTap('C'), isTrue);
      controller.commitRemoval('C');
      
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.free);
    });

    test('Test 7: Valid sequence A -> B -> C -> D -> E completes level', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      
      expect(controller.handleTap('D'), isTrue);
      controller.commitRemoval('D');
      expect(controller.state.stripStates['E'], StripState.free);
      
      expect(controller.handleTap('E'), isTrue);
      controller.commitRemoval('E');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 8: Valid sequence A -> B -> D -> C -> E completes level', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      
      expect(controller.handleTap('D'), isTrue);
      controller.commitRemoval('D');
      expect(controller.state.stripStates['E'], StripState.locked); // E still locked!
      
      expect(controller.handleTap('C'), isTrue);
      controller.commitRemoval('C');
      expect(controller.state.stripStates['E'], StripState.free); // E now free!
      
      expect(controller.handleTap('E'), isTrue);
      controller.commitRemoval('E');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 9: Reset restores graph state', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('D'); controller.commitRemoval('D');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.locked);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
    });
  });

  group('Level 6 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_6');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 5);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isTrue);
      expect(graph.isFree('D'), isTrue);
      expect(graph.isFree('C'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.hasCycle(), isFalse);
    });

    test('Test 2: A, B, D are free initially, others locked', () {
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('Test 3: Attempting C, E initially fails', () {
      expect(controller.handleTap('C'), isFalse);
      expect(controller.handleTap('E'), isFalse);
    });

    test('Test 4: Removing A does not free C', () {
      expect(controller.handleTap('A'), isTrue);
      controller.commitRemoval('A');
      
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 5: Removing B does not free C', () {
      expect(controller.handleTap('B'), isTrue);
      controller.commitRemoval('B');
      
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 6: Removing A and B frees C', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      
      expect(controller.state.stripStates['C'], StripState.free);
    });

    test('Test 7: Removing C does not free E until D is removed', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('Test 8: Removing C and D frees E', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('D'); controller.commitRemoval('D');
      
      expect(controller.state.stripStates['E'], StripState.free);
    });

    test('Test 9: Valid sequence A -> B -> D -> C -> E completes level', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 10: Valid sequence D -> B -> A -> C -> E completes level', () {
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 11: Reset restores graph state', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('D'); controller.commitRemoval('D');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
    });
  });

  group('Level 7 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_7');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 6);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isTrue);
      expect(graph.isFree('D'), isTrue);
      expect(graph.isFree('C'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.isFree('F'), isFalse);
      expect(graph.hasCycle(), isFalse);
    });

    test('Test 2: A, B, D are free initially, others locked', () {
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
    });

    test('Test 3: Attempting C, E, F initially fails', () {
      expect(controller.handleTap('C'), isFalse);
      expect(controller.handleTap('E'), isFalse);
      expect(controller.handleTap('F'), isFalse);
    });

    test('Test 4: Removing A alone does not free C', () {
      expect(controller.handleTap('A'), isTrue);
      controller.commitRemoval('A');
      
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 5: Removing B frees F, but does NOT free C if A is still present', () {
      expect(controller.handleTap('B'), isTrue);
      controller.commitRemoval('B');
      
      expect(controller.state.stripStates['F'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 6: Removing A and B frees C', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      
      expect(controller.state.stripStates['C'], StripState.free);
    });

    test('Test 7: Removing C alone does not free E', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('Test 8: Removing D alone does not free E', () {
      controller.handleTap('D'); controller.commitRemoval('D');
      
      expect(controller.state.stripStates['E'], StripState.locked);
    });

    test('Test 9: Removing C and D frees E', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('D'); controller.commitRemoval('D');
      
      expect(controller.state.stripStates['E'], StripState.free);
    });

    test('Test 10: Valid sequence A -> B -> C -> D -> E -> F completes level', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      controller.handleTap('F'); controller.commitRemoval('F');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 11: Valid sequence D -> B -> F -> A -> C -> E completes level', () {
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('F'); controller.commitRemoval('F');
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 12: Reset restores graph state', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('F'); controller.commitRemoval('F');
      controller.handleTap('A'); controller.commitRemoval('A');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
    });
  });

  group('Level 8 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_8');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 6);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isTrue);
      expect(graph.isFree('D'), isTrue);
      expect(graph.isFree('C'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.isFree('F'), isFalse);
      expect(graph.hasCycle(), isFalse);
    });

    test('Test 2: A, B, D are free initially, others locked', () {
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
    });

    test('Test 3: Removing A alone does not free C', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      expect(controller.state.stripStates['C'], StripState.locked);
    });

    test('Test 4: Removing B after A frees C', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      expect(controller.state.stripStates['C'], StripState.free);
    });

    test('Test 5: Removing D frees E', () {
      controller.handleTap('D'); controller.commitRemoval('D');
      expect(controller.state.stripStates['E'], StripState.free);
    });

    test('Test 6: Removing C alone does not free F', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      
      expect(controller.state.stripStates['F'], StripState.locked);
    });

    test('Test 7: Removing E alone does not free F', () {
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      expect(controller.state.stripStates['F'], StripState.locked);
    });

    test('Test 8: Removing C and E frees F', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      expect(controller.state.stripStates['F'], StripState.free);
    });

    test('Test 9: Valid sequence A -> B -> C -> D -> E -> F completes level', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      controller.handleTap('F'); controller.commitRemoval('F');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 10: Valid sequence D -> E -> A -> B -> C -> F completes level', () {
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('F'); controller.commitRemoval('F');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 11: Valid alternating sequence B -> D -> A -> E -> C -> F completes level', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('E'); controller.commitRemoval('E');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('F'); controller.commitRemoval('F');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 12: Reset restores graph state', () {
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
    });
  });

  group('Level 9 Core Mechanic Tests', () {
    late PuzzleLevel level;
    late DependencyGraph graph;
    late GameController controller;

    setUp(() {
      level = LevelRepository.getLevel('level_9');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      controller = GameController(
        audioService: MockAudioService(),
        hapticService: MockHapticService(),
      );
      controller.loadLevel(level);
    });

    test('Test 1: Initial graph indegrees', () {
      expect(level.strips.length, 7);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isTrue);
      expect(graph.isFree('C'), isTrue);
      expect(graph.isFree('G'), isTrue);
      expect(graph.isFree('D'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.isFree('F'), isFalse);
      expect(graph.hasCycle(), isFalse);
    });

    test('Test 2: A, B, C, G are free initially, others locked', () {
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['G'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
    });

    test('Test 3: Removing A alone does not free D', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      expect(controller.state.stripStates['D'], StripState.locked);
    });

    test('Test 4: Removing B after A frees D', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      expect(controller.state.stripStates['D'], StripState.free);
    });

    test('Test 5: Removing C frees E', () {
      controller.handleTap('C'); controller.commitRemoval('C');
      expect(controller.state.stripStates['E'], StripState.free);
    });

    test('Test 6: Removing G alone does not free F', () {
      controller.handleTap('G'); controller.commitRemoval('G');
      expect(controller.state.stripStates['F'], StripState.locked);
    });

    test('Test 7: Removing D and E without G does not free F', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('D'); controller.commitRemoval('D');
      
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      expect(controller.state.stripStates['F'], StripState.locked);
    });

    test('Test 8: Removing D, E, and G frees F', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('D'); controller.commitRemoval('D');
      
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('E'); controller.commitRemoval('E');
      
      controller.handleTap('G'); controller.commitRemoval('G');
      
      expect(controller.state.stripStates['F'], StripState.free);
    });

    test('Test 9: Valid sequence A -> B -> C -> G -> D -> E -> F completes level', () {
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('G'); controller.commitRemoval('G');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('E'); controller.commitRemoval('E');
      controller.handleTap('F'); controller.commitRemoval('F');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 10: Valid sequence G -> C -> A -> B -> E -> D -> F completes level', () {
      controller.handleTap('G'); controller.commitRemoval('G');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('E'); controller.commitRemoval('E');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('F'); controller.commitRemoval('F');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 11: Valid sequence B -> A -> D -> C -> E -> G -> F completes level', () {
      controller.handleTap('B'); controller.commitRemoval('B');
      controller.handleTap('A'); controller.commitRemoval('A');
      controller.handleTap('D'); controller.commitRemoval('D');
      controller.handleTap('C'); controller.commitRemoval('C');
      controller.handleTap('E'); controller.commitRemoval('E');
      controller.handleTap('G'); controller.commitRemoval('G');
      controller.handleTap('F'); controller.commitRemoval('F');
      
      expect(controller.state.activeStrips.isEmpty, isTrue);
      expect(controller.state.isComplete, isTrue);
    });

    test('Test 12: Reset restores graph state', () {
      controller.handleTap('G'); controller.commitRemoval('G');
      controller.handleTap('C'); controller.commitRemoval('C');
      
      controller.loadLevel(level);
      
      expect(controller.state.stripStates['A'], StripState.free);
      expect(controller.state.stripStates['B'], StripState.free);
      expect(controller.state.stripStates['C'], StripState.free);
      expect(controller.state.stripStates['G'], StripState.free);
      expect(controller.state.stripStates['D'], StripState.locked);
      expect(controller.state.stripStates['E'], StripState.locked);
      expect(controller.state.stripStates['F'], StripState.locked);
    });
  });
}
