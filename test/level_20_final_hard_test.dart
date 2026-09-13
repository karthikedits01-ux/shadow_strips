import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  group('Level 20 Revised 5-Strip Topology Verification', () {
    test('Runtime DAG matches the exact 5-strip image-based knot', () {
      final level = LevelRepository.getLevel('level_20');
      
      // 1. exact strip count
      expect(level.strips.length, 5, reason: 'Level 20 should have exactly 5 strips');

      final graph = DependencyGraph.fromCrossings(
        level.strips,
        level.crossings,
      );

      // 2. exactly one initial free strip
      final freeStrips = graph.getFreeNodes();
      expect(freeStrips.length, 1, reason: 'Exactly one initial free strip');
      expect(freeStrips.first, 'S_V1');

      // Helper to check if A directly blocks B based on physical crossings
      bool blocks(String a, String b) {
        return level.crossings.any((c) => c.upperStripId == a && c.lowerStripId == b);
      }

      int inDegreeOf(String node) {
        return level.crossings.where((c) => c.lowerStripId == node).length;
      }

      // 3. Expected physical dependencies exactly:
      // S_V1 -> S_V3
      // S_V1 -> S_HMAIN
      // S_V3 -> S_HMAIN
      // S_V1 -> S_V2
      // S_V3 -> S_V2
      // S_HMAIN -> S_V2
      // S_V1 -> S_HTOP
      // S_V2 -> S_HTOP
      expect(blocks('S_V1', 'S_V3'), isTrue);
      expect(blocks('S_V1', 'S_HMAIN'), isTrue);
      expect(blocks('S_V3', 'S_HMAIN'), isTrue);
      expect(blocks('S_V1', 'S_V2'), isTrue);
      expect(blocks('S_V3', 'S_V2'), isTrue);
      expect(blocks('S_HMAIN', 'S_V2'), isTrue);
      expect(blocks('S_V1', 'S_HTOP'), isTrue);
      expect(blocks('S_V2', 'S_HTOP'), isTrue);

      // Verify total edges = 8
      expect(level.crossings.length, 8, reason: 'Exactly 8 dependencies should exist with no phantom crossings');

      // Expected indegrees:
      // S_V1 = 0
      // S_V3 = 1
      // S_HMAIN = 2
      // S_V2 = 3
      // S_HTOP = 2
      expect(inDegreeOf('S_V1'), 0);
      expect(inDegreeOf('S_V3'), 1);
      expect(inDegreeOf('S_HMAIN'), 2);
      expect(inDegreeOf('S_V2'), 3);
      expect(inDegreeOf('S_HTOP'), 2);

      // Expected valid extraction order:
      // S_V1 -> S_V3 -> S_HMAIN -> S_V2 -> S_HTOP
      final extractionOrder = <String>[];
      while (true) {
        final currentFree = graph.getFreeNodes();
        if (currentFree.isEmpty) break;
        
        final listFree = currentFree.toList()..sort();
        final toRemove = listFree.first;
        extractionOrder.add(toRemove);
        graph.removeNode(toRemove);
      }

      // Verify full extraction
      expect(extractionOrder.length, 5, reason: 'All 5 strips must be successfully extracted');
      expect(graph.getFreeNodes().isEmpty, isTrue, reason: 'Graph should be empty after full extraction');

      // Verify exact expected order
      expect(extractionOrder[0], 'S_V1');
      expect(extractionOrder[1], 'S_V3');
      expect(extractionOrder[2], 'S_HMAIN');
      expect(extractionOrder[3], 'S_V2');
      expect(extractionOrder[4], 'S_HTOP');
    });

    test('invalid blocked extraction is rejected', () {
      final level = LevelRepository.getLevel('level_20');
      final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

      // Try to remove a blocked strip
      expect(() => graph.removeNode('S_V2'), throwsA(isA<StateError>()));
      expect(() => graph.removeNode('S_HMAIN'), throwsA(isA<StateError>()));
    });
  });
}
