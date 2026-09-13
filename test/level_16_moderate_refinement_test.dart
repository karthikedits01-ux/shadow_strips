import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  group('Level 16 Moderate Difficulty Refinement Tests', () {
    late DependencyGraph graph;

    setUp(() {
      final level = LevelRepository.getLevel('level_16');
      graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    });

    test('Graph is properly initialized', () {
      expect(graph.hasCycle(), isFalse);
      
      // Exactly 1 free strip initially
      final freeStrips = graph.getFreeNodes();
      expect(freeStrips.length, 1);
      expect(freeStrips.first, 'H1');
    });

    test('Crossings generate expected indegrees indirectly', () {
      // H1 crosses V1, V2 -> V1, V2 blocked by H1
      // V1 crosses H2 -> H2 blocked by V1
      // V2 crosses H2, H3 -> H2, H3 blocked by V2
      // H2 crosses V3 -> V3 blocked by H2
      // V3 crosses H3 -> H3 blocked by V3

      expect(graph.isFree('H1'), isTrue);
      expect(graph.isFree('V1'), isFalse);
      expect(graph.isFree('V2'), isFalse);
      expect(graph.isFree('H2'), isFalse);
      expect(graph.isFree('V3'), isFalse);
      expect(graph.isFree('H3'), isFalse);
    });

    test('Valid path 1: H1 -> V1 -> V2 -> H2 -> V3 -> H3', () {
      // Step 1: Remove H1
      expect(graph.getFreeNodes(), ['H1']);
      graph.removeNode('H1');

      // Both V1 and V2 should now be free (Branching!)
      final freeAfterH1 = graph.getFreeNodes();
      expect(freeAfterH1.length, 2);
      expect(freeAfterH1, contains('V1'));
      expect(freeAfterH1, contains('V2'));

      // Step 2: Remove V1
      graph.removeNode('V1');
      
      // H2 is still blocked by V2, so only V2 is free
      final freeAfterV1 = graph.getFreeNodes();
      expect(freeAfterV1.length, 1);
      expect(freeAfterV1, contains('V2'));
      
      // Step 3: Remove V2
      graph.removeNode('V2');
      
      // Now H2 is free
      final freeAfterV2 = graph.getFreeNodes();
      expect(freeAfterV2.length, 1);
      expect(freeAfterV2, contains('H2'));
      
      // Step 4: Remove H2
      graph.removeNode('H2');
      
      // Now V3 is free
      final freeAfterH2 = graph.getFreeNodes();
      expect(freeAfterH2.length, 1);
      expect(freeAfterH2, contains('V3'));

      // Step 5: Remove V3
      graph.removeNode('V3');
      
      // Now H3 is free
      final freeAfterV3 = graph.getFreeNodes();
      expect(freeAfterV3.length, 1);
      expect(freeAfterV3, contains('H3'));
      
      // Step 6: Remove H3
      graph.removeNode('H3');
      expect(graph.getFreeNodes(), isEmpty);
    });
    
    test('Valid path 2: H1 -> V2 -> V1 -> H2 -> V3 -> H3', () {
      // Step 1: Remove H1
      graph.removeNode('H1');

      // Branching: Remove V2 first this time
      graph.removeNode('V2');
      
      // H3 is still blocked by V3. H2 is still blocked by V1.
      // So only V1 is free right now.
      final freeAfterV2 = graph.getFreeNodes();
      expect(freeAfterV2.length, 1);
      expect(freeAfterV2, contains('V1'));

      // Step 3: Remove V1
      graph.removeNode('V1');
      
      // Now H2 is free
      final freeAfterV1 = graph.getFreeNodes();
      expect(freeAfterV1.length, 1);
      expect(freeAfterV1, contains('H2'));
      
      // Step 4: Remove H2
      graph.removeNode('H2');
      
      // Now V3 is free
      final freeAfterH2 = graph.getFreeNodes();
      expect(freeAfterH2.length, 1);
      expect(freeAfterH2, contains('V3'));

      // Step 5: Remove V3
      graph.removeNode('V3');
      
      // Now H3 is free
      final freeAfterV3 = graph.getFreeNodes();
      expect(freeAfterV3.length, 1);
      expect(freeAfterV3, contains('H3'));
      
      // Step 6: Remove H3
      graph.removeNode('H3');
      expect(graph.getFreeNodes(), isEmpty);
    });
  });
}
