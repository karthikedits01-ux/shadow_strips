// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  test('Level 21 Topology Verification via Actual Engine', () {
    final level = LevelRepository.getLevel('level_21');
    final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);

    print("=== ACTUAL DEPENDENCY EDGES ===");
    for (var crossing in level.crossings) {
      print("${crossing.upperStripId} -> ${crossing.lowerStripId}");
    }

    print("\n=== INITIAL FREE STRIPS ===");
    final freeNodes = graph.getFreeNodes();
    print(freeNodes.join(', '));

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
    
    if (remainingStrips.isEmpty) {
      print("SUCCESS: Valid extraction sequence!");
      print(extractionOrder.join(' -> '));
    }
  });
}
