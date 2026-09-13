// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';
import 'package:shadow_strips/rendering/hit_test_engine.dart';
import 'package:shadow_strips/models/game_state.dart';
import 'package:shadow_strips/models/strip.dart';

void main() {
  test('Level 22 Topology Verification via Actual Engine', () {
    final level = LevelRepository.getLevel('level_22');
    final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

    print("=== INITIAL FREE STRIPS ===");
    final freeNodes = graph.getFreeNodes();
    print(freeNodes.join(', '));

    expect(freeNodes.length, 1, reason: "Level 22 should have exactly 1 initial free strip");
    expect(freeNodes.first, 'S4');

    print("\n=== FULL EXTRACTION SEQUENCE ===");
    final remainingStrips = level.strips.map((s) => s.id).toList();
    List<String> extractionOrder = [];
    
    int iteration = 0;
    while (remainingStrips.isNotEmpty && iteration < 100) {
      iteration++;
      final currentFree = graph.getFreeNodes();
      
      if (currentFree.isEmpty) {
        print("CYCLE DETECTED OR STUCK! Remaining: ${remainingStrips.join(', ')}");
        break;
      }

      final currentFreeList = currentFree.toList();
      currentFreeList.sort();
      final toRemove = currentFreeList.first;
      
      print("Step $iteration: Extracted $toRemove");
      extractionOrder.add(toRemove);
      graph.removeNode(toRemove);
      remainingStrips.remove(toRemove);
    }
    
    expect(remainingStrips.isEmpty, true, reason: "Must be fully extractable");
    expect(extractionOrder.length, 13, reason: "Must extract all 13 strips");
    
    final expectedOrder = [
      'S4', 'S1', 'S2', 'S3', 'S8', 'S5', 'S6', 'S7', 'S9', 'S11', 'S10', 'S13', 'S12'
    ];
    
    expect(extractionOrder, expectedOrder, reason: "Must follow the strict ordered path");
  });

  test('Level 22 Hit Testing and Touch Disambiguation Test', () {
    final level = LevelRepository.getLevel('level_22');
    final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    final drawOrder = graph.getTopologicalDrawOrder();
    
    final stripStates = {for (var s in level.strips) s.id: StripState.free};
    final activeStrips = {for (var s in level.strips) s.id: s};
    
    final state = GameState(
      levelId: 'level_22',
      stripStates: stripStates,
      activeStrips: activeStrips,
      drawOrder: drawOrder,
      mistakes: 0,
      isComplete: false,
      isGameOver: false,
    );

    // 1. Direct hit on S4 (V Left at X=200)
    expect(HitTestEngine.hitTest(const Offset(200, 500), state, physicalScale: 0.5), 'S4');
    
    // 2. Off-center hit within visual body (e.g. at X=215, half-width is 18.5)
    expect(HitTestEngine.hitTest(const Offset(215, 500), state, physicalScale: 0.5), 'S4');
    
    // 3. Near-miss hit with touch tolerance (e.g. at X=228, within touch tolerance)
    expect(HitTestEngine.hitTest(const Offset(228, 500), state, physicalScale: 0.5), 'S4');

    // 4. Disambiguation in center hash:
    // S9 is at X=465, S10 is at X=535.
    // Tap closer to S9 (X=480, distance to S9=15, distance to S10=55) -> must hit S9
    expect(HitTestEngine.hitTest(const Offset(480, 600), state, physicalScale: 0.5), 'S9');
    
    // Tap closer to S10 (X=520, distance to S10=15, distance to S9=55) -> must hit S10
    expect(HitTestEngine.hitTest(const Offset(520, 600), state, physicalScale: 0.5), 'S10');

    // 5. Crossing intersection between S4 (X=200, z=130) and S1 (Y=200, z=120):
    // At crossing (200, 200), S4 is higher zIndex -> S4 must be returned
    expect(HitTestEngine.hitTest(const Offset(200, 200), state, physicalScale: 0.5), 'S4');
  });
}
