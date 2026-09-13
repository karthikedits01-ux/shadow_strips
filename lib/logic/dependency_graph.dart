import '../models/crossing.dart';
import '../models/strip.dart';

/// Implements a deterministic directed acyclic graph (DAG) for the puzzle engine.
/// 
/// Nodes are Strip IDs. Edges are dependencies (upper -> lower).
/// A strip is removable only when its indegree == 0 (no remaining strips lie above it).
class DependencyGraph {
  /// The edges: Key is an upper strip ID, Value is a set of lower strip IDs it blocks.
  final Map<String, Set<String>> _outgoingEdges = {};
  
  /// The indegrees: Key is a strip ID, Value is the number of strips that lie above it.
  final Map<String, int> _indegrees = {};

  DependencyGraph();

  factory DependencyGraph.fromCrossings(List<Strip> strips, List<Crossing> crossings) {
    final graph = DependencyGraph();
    
    // Initialize all nodes with 0 indegree
    for (final strip in strips) {
      graph.addNode(strip.id);
    }
    
    // Add all dependency edges
    for (final crossing in crossings) {
      graph.addEdge(crossing.upperStripId, crossing.lowerStripId);
    }
    
    return graph;
  }

  void addNode(String nodeId) {
    if (!_indegrees.containsKey(nodeId)) {
      _indegrees[nodeId] = 0;
      _outgoingEdges[nodeId] = {};
    }
  }

  /// Adds a dependency edge: `upperId` -> `lowerId`.
  /// Meaning `upperId` must be extracted before `lowerId` can be freed.
  void addEdge(String upperId, String lowerId) {
    // Ensure nodes exist
    addNode(upperId);
    addNode(lowerId);

    // Prevent duplicate edges
    if (!_outgoingEdges[upperId]!.contains(lowerId)) {
      _outgoingEdges[upperId]!.add(lowerId);
      _indegrees[lowerId] = _indegrees[lowerId]! + 1;
    }
  }

  /// Returns the IDs of all strips that have no dependencies (indegree == 0).
  Set<String> getFreeNodes() {
    return _indegrees.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Returns true if the specified node has no dependencies.
  bool isFree(String nodeId) {
    return _indegrees[nodeId] == 0;
  }

  /// Removes a node and updates the dependencies of the nodes it blocked.
  /// Throws an error if the node is not free or doesn't exist.
  void removeNode(String nodeId) {
    if (!_indegrees.containsKey(nodeId)) {
      throw ArgumentError('Node $nodeId does not exist.');
    }
    if (_indegrees[nodeId]! > 0) {
      throw StateError('Cannot remove node $nodeId because it is not free (indegree > 0).');
    }

    // Decrement indegree for all children
    final children = _outgoingEdges[nodeId]!;
    for (final child in children) {
      _indegrees[child] = _indegrees[child]! - 1;
    }

    // Remove the node entirely
    _outgoingEdges.remove(nodeId);
    _indegrees.remove(nodeId);
  }

  /// Returns true if there are cycles in the graph (i.e. it's not a valid DAG).
  bool hasCycle() {
    final visited = <String>{};
    final recursionStack = <String>{};

    bool dfs(String node) {
      if (recursionStack.contains(node)) return true;
      if (visited.contains(node)) return false;

      visited.add(node);
      recursionStack.add(node);

      final children = _outgoingEdges[node] ?? {};
      for (final child in children) {
        if (dfs(child)) return true;
      }

      recursionStack.remove(node);
      return false;
    }

    for (final node in _indegrees.keys) {
      if (dfs(node)) return true;
    }

    return false;
  }

  /// Creates a deep copy of the current graph state.
  DependencyGraph clone() {
    final copy = DependencyGraph();
    
    // Copy indegrees
    for (final entry in _indegrees.entries) {
      copy._indegrees[entry.key] = entry.value;
    }
    
    // Copy edges
    for (final entry in _outgoingEdges.entries) {
      copy._outgoingEdges[entry.key] = Set.from(entry.value);
    }
    
    return copy;
  }
  
  /// Returns a topological ordering of the nodes from bottom to top.
  /// A node is guaranteed to appear AFTER all nodes it blocks.
  /// (i.e. if A blocks B, the order will be [... B ... A ...])
  /// This guarantees the visual drawing order exactly matches the logical truth.
  List<String> getTopologicalDrawOrder() {
    final indegrees = Map<String, int>.from(_indegrees);
    final zeroIndegreeQueue = <String>[];
    
    // Sort keys for deterministic output
    final sortedKeys = indegrees.keys.toList()..sort();
    
    for (final key in sortedKeys) {
      if (indegrees[key] == 0) {
        zeroIndegreeQueue.add(key);
      }
    }
    
    final topToBottom = <String>[];
    
    while (zeroIndegreeQueue.isNotEmpty) {
      zeroIndegreeQueue.sort(); 
      final current = zeroIndegreeQueue.removeAt(0);
      topToBottom.add(current);
      
      final children = _outgoingEdges[current] ?? {};
      for (final child in children) {
        indegrees[child] = indegrees[child]! - 1;
        if (indegrees[child] == 0) {
          zeroIndegreeQueue.add(child);
        }
      }
    }
    
    // Kahn's gives us Top-to-Bottom (A before B).
    // We reverse it to get Bottom-to-Top (B before A, so A paints over B).
    return topToBottom.reversed.toList();
  }
  
  bool get isEmpty => _indegrees.isEmpty;
  int get nodeCount => _indegrees.length;
}
