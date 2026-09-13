import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  group('Level 17 Topological Dependency Tests', () {
    late DependencyGraph graph;

    setUp(() {
      final level = LevelRepository.getLevel('level_17');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    });

    test('Graph is properly initialized', () {
      expect(graph.hasCycle(), isFalse);
      
      final level = LevelRepository.getLevel('level_17');
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
      expect(graph.isFree('D_bent'), isFalse);
      expect(graph.isFree('E'), isFalse);
      expect(graph.isFree('F'), isFalse);
      expect(graph.isFree('G'), isFalse);
    });

    test('Removing A frees B, E, and G', () {
      graph.removeNode('A');

      final freeNodes = graph.getFreeNodes();
      expect(freeNodes.length, 3);
      expect(freeNodes, containsAll(['B', 'E', 'G']));
    });

    test('D_bent remains locked until BOTH C and E are removed', () {
      graph.removeNode('A');
      
      // Remove E (horizontal leg blocker)
      graph.removeNode('E');
      
      // D_bent still blocked by C
      expect(graph.isFree('D_bent'), isFalse);
      
      // Remove B to unlock C
      graph.removeNode('B');
      expect(graph.isFree('C'), isTrue);
      
      // Remove C (vertical leg blocker)
      graph.removeNode('C');
      
      // NOW D_bent is free
      expect(graph.isFree('D_bent'), isTrue);
    });
    
    test('F remains locked until E, D_bent and G are removed', () {
      graph.removeNode('A');

      // Clear the left branch to unlock D_bent
      graph.removeNode('B');
      graph.removeNode('C');
      
      // Clear E
      graph.removeNode('E');
      
      // Clear D_bent
      graph.removeNode('D_bent');
      
      // F is still locked because G is present
      expect(graph.isFree('F'), isFalse);
      
      // Remove G
      graph.removeNode('G');
      
      // NOW F is free
      expect(graph.isFree('F'), isTrue);
    });

    test('Valid solution path completing the level', () {
      // Intended solution path: A -> B -> C -> E -> D_bent -> G -> F
      // (Wait, G can be removed anytime after A)
      graph.removeNode('A');
      
      final free1 = graph.getFreeNodes();
      expect(free1, containsAll(['B', 'E', 'G']));
      
      graph.removeNode('B');
      expect(graph.getFreeNodes(), containsAll(['C', 'E', 'G']));
      
      graph.removeNode('C');
      expect(graph.getFreeNodes(), containsAll(['E', 'G']));
      
      graph.removeNode('E');
      expect(graph.getFreeNodes(), containsAll(['D_bent', 'G']));
      
      graph.removeNode('D_bent');
      expect(graph.getFreeNodes(), containsAll(['G']));
      
      graph.removeNode('G');
      expect(graph.getFreeNodes(), ['F']);
      
      graph.removeNode('F');
      
      expect(graph.getFreeNodes(), isEmpty);
    });
  });
}
