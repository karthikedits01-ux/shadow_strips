import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/level_repository.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';

void main() {
  group('Level 19 Advanced Topological Tracing DAG Verification', () {
    test('Runtime DAG matches the rigorous mathematical proof exactly', () {
      final level = LevelRepository.getLevel('level_19');
      final graph = DependencyGraph.fromCrossings(
        level.strips,
        level.crossings,
      );


      // Check Indegrees indirectly by verifying what is free
      final freeStrips = graph.getFreeNodes();
      expect(freeStrips.length, 1, reason: 'Exactly one initial free strip');
      expect(freeStrips.first, 'A');

      expect(graph.isFree('B'), isFalse);
      expect(graph.isFree('C'), isFalse);
      expect(graph.isFree('D'), isFalse);
      expect(graph.isFree('C2'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.isFree('F'), isFalse);
      expect(graph.isFree('G'), isFalse);

      // Verify A blocks B, C, D, C2
      graph.removeNode('A');
      final afterA = graph.getFreeNodes();
      expect(afterA.length, 4);
      expect(afterA, containsAll(['B', 'C', 'D', 'C2']));

      // Verify B blocks E, but C also blocks E
      graph.removeNode('B');
      expect(graph.isFree('E'), isFalse, reason: 'E still blocked by C');

      graph.removeNode('C');
      expect(
        graph.isFree('E'),
        isTrue,
        reason: 'E freed after B and C removed',
      );
      expect(graph.isFree('F'), isFalse, reason: 'F still blocked by D');

      // Verify D blocks F
      graph.removeNode('D');
      expect(
        graph.isFree('F'),
        isTrue,
        reason: 'F freed after C and D removed',
      );

      // Verify E, F, C2 block G
      expect(graph.isFree('G'), isFalse);
      graph.removeNode('E');
      expect(graph.isFree('G'), isFalse);
      graph.removeNode('F');
      expect(graph.isFree('G'), isFalse);
      graph.removeNode('C2');
      expect(
        graph.isFree('G'),
        isTrue,
        reason: 'G freed after E, F, C2 removed',
      );

      graph.removeNode('G');
      expect(graph.getFreeNodes(), isEmpty);
    });
  });
}
