import 'dart:math';

class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
  double get distance => sqrt(dx*dx + dy*dy);
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);
}
class Strip {
  final String id;
  final List<Offset> points;
  final double width;
  final int zIndex;
  Strip({required this.id, required this.points, required this.width, required this.zIndex});
}

class Crossing {
  final String upperStripId;
  final String lowerStripId;
  Crossing(this.upperStripId, this.lowerStripId);
}

double _segmentDistance(Offset p1, Offset p2, Offset q1, Offset q2) {
  if (_doIntersect(p1, p2, q1, q2)) return 0.0;
  final d1 = _pointToSegmentDist(p1, q1, q2);
  final d2 = _pointToSegmentDist(p2, q1, q2);
  final d3 = _pointToSegmentDist(q1, p1, p2);
  final d4 = _pointToSegmentDist(q2, p1, p2);
  return [d1, d2, d3, d4].reduce(min);
}

bool _doIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
  int o1 = _orientation(p1, q1, p2);
  int o2 = _orientation(p1, q1, q2);
  int o3 = _orientation(p2, q2, p1);
  int o4 = _orientation(p2, q2, q1);
  if (o1 != o2 && o3 != o4) return true;
  return false;
}

int _orientation(Offset p, Offset q, Offset r) {
  double val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
  if (val.abs() < 1e-6) return 0;
  return (val > 0) ? 1 : 2;
}

double _pointToSegmentDist(Offset p, Offset a, Offset b) {
  final l2 = (a.dx - b.dx) * (a.dx - b.dx) + (a.dy - b.dy) * (a.dy - b.dy);
  if (l2 == 0) return (p - a).distance;
  var t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
  t = max(0, min(1, t));
  final proj = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
  return (p - proj).distance;
}

void main() {
  // Define the Star Points
  final T0 = Offset(195, 120); // Top
  final T1 = Offset(360, 240); // Right
  final T2 = Offset(300, 430); // Bottom Right
  final T3 = Offset(90, 430);  // Bottom Left
  final T4 = Offset(30, 240);  // Left

  // Inner pentagon corners
  final I0 = Offset(145, 240); // Top Left Inner
  final I1 = Offset(245, 240); // Top Right Inner
  final I2 = Offset(275, 335); // Bottom Right Inner
  final I3 = Offset(195, 395); // Bottom Inner
  final I4 = Offset(115, 335); // Bottom Left Inner

  final strips = [
    // The core pentagram (5 strips)
    Strip(id: 'S_PENTA_1', points: [T3, T0], width: 40.0, zIndex: 10), // Bottom Left to Top
    Strip(id: 'S_CAP_BL', points: [I3, T3, I4], width: 40.0, zIndex: 20),
    Strip(id: 'S_PENTA_5', points: [T1, T3], width: 40.0, zIndex: 30), // Right to Bottom Left
    Strip(id: 'S_CAP_R', points: [I1, T1, I2], width: 40.0, zIndex: 40),
    Strip(id: 'S_PENTA_4', points: [T4, T1], width: 40.0, zIndex: 50), // Left to Right
    Strip(id: 'S_CAP_L', points: [I4, T4, I0], width: 40.0, zIndex: 60),
    Strip(id: 'S_PENTA_3', points: [T2, T4], width: 40.0, zIndex: 70), // Bottom Right to Left
    Strip(id: 'S_CAP_BR', points: [I2, T2, I3], width: 40.0, zIndex: 80),
    Strip(id: 'S_PENTA_2', points: [T0, T2], width: 40.0, zIndex: 90), // Top to Bottom Right
    Strip(id: 'S_CAP_TOP', points: [I0, T0, I1], width: 40.0, zIndex: 100),
  ];

  // Calculate crossings
  final crossings = <Crossing>[];
  for (int i = 0; i < strips.length; i++) {
    for (int j = i + 1; j < strips.length; j++) {
      final s1 = strips[i];
      final s2 = strips[j];
      bool intersect = false;
      for (int k = 0; k < s1.points.length - 1; k++) {
        for (int l = 0; l < s2.points.length - 1; l++) {
          if (_segmentDistance(s1.points[k], s1.points[k+1], s2.points[l], s2.points[l+1]) < (s1.width + s2.width) / 2.0 * 0.9) {
            intersect = true; break;
          }
        }
        if (intersect) break;
      }
      if (intersect) {
        if (s1.zIndex > s2.zIndex) {
          crossings.add(Crossing(s1.id, s2.id));
        } else {
          crossings.add(Crossing(s2.id, s1.id));
        }
      }
    }
  }

  // Dependency Graph
  final Map<String, List<String>> edges = {};
  final Map<String, int> inDegree = {};
  for (var s in strips) {
    edges[s.id] = [];
    inDegree[s.id] = 0;
  }
  for (var c in crossings) {
    edges[c.upperStripId]!.add(c.lowerStripId);
    inDegree[c.lowerStripId] = inDegree[c.lowerStripId]! + 1;
    print("${c.upperStripId} -> ${c.lowerStripId}");
  }

  print("=== IN-DEGREES ===");
  for (var s in strips) {
    print("${s.id}: ${inDegree[s.id]}");
  }

  // Solve
  List<String> free = strips.where((s) => inDegree[s.id] == 0).map((s) => s.id).toList();
  List<String> order = [];
  while (free.isNotEmpty) {
    free.sort();
    final node = free.removeAt(0);
    order.add(node);
    for (var neighbor in edges[node]!) {
      inDegree[neighbor] = inDegree[neighbor]! - 1;
      if (inDegree[neighbor] == 0) free.add(neighbor);
    }
  }

  if (order.length == strips.length) {
    print("Valid DAG! Solution: $order");
  } else {
    print("CYCLE DETECTED! Only extracted: $order");
  }
}
