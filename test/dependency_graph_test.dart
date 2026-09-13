import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/models/crossing.dart';
import 'package:shadow_strips/models/strip.dart';

void main() {
  group('DependencyGraph', () {
    test('Nodes and edges are correctly initialized', () {
      final strips = [
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
      ];
      final crossings = [const Crossing(upperStripId: 'A', lowerStripId: 'B')];

      final graph = DependencyGraph.fromCrossings(strips, crossings);

      expect(graph.nodeCount, 2);
      expect(graph.isFree('A'), isTrue);
      expect(graph.isFree('B'), isFalse);
    });

    test('getFreeNodes returns correctly', () {
      final graph = DependencyGraph();
      graph.addEdge('A', 'B');
      graph.addEdge('A', 'C');
      graph.addNode('D'); // D has no edges

      final freeNodes = graph.getFreeNodes();
      expect(freeNodes.contains('A'), isTrue);
      expect(freeNodes.contains('D'), isTrue);
      expect(freeNodes.contains('B'), isFalse);
    });

    test('removeNode updates indegrees correctly', () {
      final graph = DependencyGraph();
      graph.addEdge('A', 'B');
      graph.addEdge('A', 'C');

      expect(graph.isFree('B'), isFalse);

      graph.removeNode('A');

      expect(graph.isFree('B'), isTrue);
      expect(graph.isFree('C'), isTrue);
      expect(graph.nodeCount, 2); // B and C remain
    });

    test('removeNode throws if node is not free', () {
      final graph = DependencyGraph();
      graph.addEdge('A', 'B');

      expect(() => graph.removeNode('B'), throwsStateError);
    });

    test('hasCycle detects cycles', () {
      final graph = DependencyGraph();
      graph.addEdge('A', 'B');
      graph.addEdge('B', 'C');
      graph.addEdge('C', 'A');

      expect(graph.hasCycle(), isTrue);
    });

    test('hasCycle returns false for valid DAG', () {
      final graph = DependencyGraph();
      graph.addEdge('A', 'B');
      graph.addEdge('A', 'C');
      graph.addEdge('B', 'D');
      graph.addEdge('C', 'D');

      expect(graph.hasCycle(), isFalse);
    });
  });
}
