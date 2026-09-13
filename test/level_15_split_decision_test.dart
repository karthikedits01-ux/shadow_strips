import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  group('Level 15 Split Decision Tests', () {
    test('1. Exactly 6 strips exist.', () {
      final level = LevelRepository.getLevel('level_15');
      expect(level.strips.length, 6);
    });

    test('2-8. Exact dependencies and no unintended dependencies exist.', () {
      final level = LevelRepository.getLevel('level_15');


      expect(level.crossings.length, 6, reason: 'Expected exactly 6 dependencies');

      bool hasAD = level.crossings.any((c) => c.upperStripId == 'A' && c.lowerStripId == 'D');
      bool hasBD = level.crossings.any((c) => c.upperStripId == 'B' && c.lowerStripId == 'D');
      bool hasAE = level.crossings.any((c) => c.upperStripId == 'A' && c.lowerStripId == 'E');
      bool hasCE = level.crossings.any((c) => c.upperStripId == 'C' && c.lowerStripId == 'E');
      bool hasDF = level.crossings.any((c) => c.upperStripId == 'D' && c.lowerStripId == 'F');
      bool hasEF = level.crossings.any((c) => c.upperStripId == 'E' && c.lowerStripId == 'F');

      expect(hasAD, isTrue, reason: 'A -> D exists');
      expect(hasBD, isTrue, reason: 'B -> D exists');
      expect(hasAE, isTrue, reason: 'A -> E exists');
      expect(hasCE, isTrue, reason: 'C -> E exists');
      expect(hasDF, isTrue, reason: 'D -> F exists');
      expect(hasEF, isTrue, reason: 'E -> F exists');
    });

    test('9-14. Initial Free / Locked states', () {
      final level = LevelRepository.getLevel('level_15');
      final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

      final freeStrips = graph.getFreeNodes();
      expect(freeStrips.contains('A'), isTrue);
      expect(freeStrips.contains('B'), isTrue);
      expect(freeStrips.contains('C'), isTrue);
      expect(freeStrips.length, 3, reason: 'A, B, C initially free');

      expect(graph.isFree('D'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.isFree('F'), isFalse);
    });

    test('15-21. Mechanics and sequential removal', () {
      final level = LevelRepository.getLevel('level_15');
      final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

      // Removing A alone does not free D or E
      graph.removeNode('A');
      expect(graph.getFreeNodes().contains('D'), isFalse);
      expect(graph.getFreeNodes().contains('E'), isFalse);

      // Removing B after A frees D
      graph.removeNode('B');
      expect(graph.getFreeNodes().contains('D'), isTrue);

      // Removing C after A frees E
      graph.removeNode('C');
      expect(graph.getFreeNodes().contains('E'), isTrue);

      // Removing D alone does not free F
      graph.removeNode('D');
      expect(graph.getFreeNodes().contains('F'), isFalse);

      // Removing E frees F
      graph.removeNode('E');
      expect(graph.getFreeNodes().contains('F'), isTrue);
    });

    test('22. Multiple valid solution orders complete the level (C -> A -> E -> B -> D -> F)', () {
      final level = LevelRepository.getLevel('level_15');
      final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

      graph.removeNode('C');
      graph.removeNode('A');
      expect(graph.getFreeNodes().contains('E'), isTrue);
      graph.removeNode('E');
      graph.removeNode('B');
      expect(graph.getFreeNodes().contains('D'), isTrue);
      graph.removeNode('D');
      expect(graph.getFreeNodes().contains('F'), isTrue);
      graph.removeNode('F');
      expect(graph.isEmpty, isTrue);
    });

    test('23. Invalid locked taps logic', () {
      final level = LevelRepository.getLevel('level_15');
      var graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

      expect(() => graph.removeNode('D'), throwsA(isA<StateError>()));
    });

    test('24-25. Reset restores initial state and no cycle exists', () {
      final level = LevelRepository.getLevel('level_15');
      var graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      
      expect(graph.hasCycle(), isFalse);
      
      graph.removeNode('A');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
      expect(graph.getFreeNodes().length, 3);
      expect(graph.getFreeNodes().contains('A'), isTrue);
    });
  });
}
