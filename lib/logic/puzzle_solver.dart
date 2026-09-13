import 'dependency_graph.dart';

/// A deterministic solver for the puzzle graph.
class PuzzleSolver {
  /// Determines if the puzzle can be completely cleared.
  static bool isSolvable(DependencyGraph graph, int stripCount) {
    try {
      final sequence = getSolutionSequence(graph, stripCount);
      return sequence.length == stripCount;
    } catch (_) {
      return false;
    }
  }

  /// Returns one valid complete extraction sequence.
  /// If multiple paths exist, it returns the first found deterministic path.
  /// Throws a [StateError] if no complete solution exists.
  static List<String> getSolutionSequence(DependencyGraph graph, int stripCount) {
    // Clone graph to avoid mutating the original
    final simGraph = graph.clone();
    
    final sequence = <String>[];

    while (!simGraph.isEmpty) {
      final freeNodes = simGraph.getFreeNodes();
      if (freeNodes.isEmpty) {
        break;
      }
      
      final sortedFreeNodes = freeNodes.toList()..sort();
      final nodeToRemove = sortedFreeNodes.first;
      
      simGraph.removeNode(nodeToRemove);
      sequence.add(nodeToRemove);
    }
    
    if (sequence.length != stripCount) {
       throw StateError('Cannot find complete solution. Solved ${sequence.length}/$stripCount');
    }

    return sequence;
  }
}

