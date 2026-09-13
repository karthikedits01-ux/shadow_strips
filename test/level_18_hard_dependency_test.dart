import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  group('Level 18 Hard Dependency Tests (Spaced Layout)', () {
    late DependencyGraph graph;

    setUp(() {
      final level = LevelRepository.getLevel('level_18');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    });

    test('Graph is properly initialized', () {
      expect(graph.hasCycle(), isFalse);
      
      final level = LevelRepository.getLevel('level_18');
      expect(level.strips.length, 7);
      
      // Exactly 1 free strip initially
      final freeStrips = graph.getFreeNodes();
      expect(freeStrips.length, 1);
      expect(freeStrips.first, 'A');
    });

    test('Crossings generate expected indegrees indirectly', () {
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isFalse);
      expect(graph.isFree('C'), isFalse);
      expect(graph.isFree('D'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.isFree('F'), isFalse);
      expect(graph.isFree('G'), isFalse);
    });
    
    test('Removing A frees B, C, and D', () {
      graph.removeNode('A');
      
      final freeNodes = graph.getFreeNodes();
      expect(freeNodes.length, 3);
      expect(freeNodes, containsAll(['B', 'C', 'D']));
    });

    test('E requires BOTH B and C to be removed (different legs)', () {
      graph.removeNode('A');
      
      // Remove B (blocks E's horizontal leg)
      graph.removeNode('B');
      
      // E is still blocked by C
      expect(graph.isFree('E'), isFalse);
      
      // Remove C (blocks E's vertical leg)
      graph.removeNode('C');
      
      // E is now free
      expect(graph.isFree('E'), isTrue);
    });
    
    test('F requires multiple deep branches (E and D)', () {
      graph.removeNode('A');

      // Clear the rightmost branch
      graph.removeNode('D');
      
      // F is still locked because E is present
      expect(graph.isFree('F'), isFalse);
      
      // Clear B and C to free E
      graph.removeNode('B');
      graph.removeNode('C');
      graph.removeNode('E');
      
      // Now F is free
      expect(graph.isFree('F'), isTrue);
    });

    test('Valid solution path completing the level', () {
      graph.removeNode('A');
      
      expect(graph.getFreeNodes(), containsAll(['B', 'C', 'D']));
      
      graph.removeNode('D');
      expect(graph.getFreeNodes(), containsAll(['B', 'C']));
      
      graph.removeNode('C');
      expect(graph.getFreeNodes(), containsAll(['B']));
      
      graph.removeNode('B');
      expect(graph.getFreeNodes(), containsAll(['E']));
      
      graph.removeNode('E');
      expect(graph.getFreeNodes(), containsAll(['F']));
      
      graph.removeNode('F');
      expect(graph.getFreeNodes(), containsAll(['G']));
      
      graph.removeNode('G');
      
      expect(graph.getFreeNodes(), isEmpty);
    });
  });
}
