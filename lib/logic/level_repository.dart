import 'dart:math';
import 'dart:ui';

import '../models/crossing.dart';
import '../models/puzzle_level.dart';
import '../models/strip.dart';
import '../models/level_metadata.dart';

/// Provides the curated levels for the game.
class LevelRepository {
  static PuzzleLevel getLevel(String id) {
    PuzzleLevel level;
    if (id.startsWith('level_')) {
      final intLevel = int.tryParse(id.split('_')[1]);
      if (intLevel != null) {
        level = _buildLevel(intLevel);
      } else {
        level = _buildLevel(1).copyWith(levelId: id); 
      }
    } else {
      level = _buildLevel(1).copyWith(levelId: id); 
    }

    final orientedStrips = _orientStripsOutward(level.strips);
    return level.copyWith(strips: orientedStrips);
  }

  static List<Strip> _orientStripsOutward(List<Strip> strips) {
    if (strips.isEmpty) return strips;
    
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    
    for (final strip in strips) {
      for (final p in strip.points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }
    
    final levelCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    
    final orientedStrips = <Strip>[];
    for (final strip in strips) {
      if (strip.points.length >= 2) {
        final head = strip.points.last;
        final tail = strip.points.first;
        
        final headDist = (head - levelCenter).distanceSquared;
        final tailDist = (tail - levelCenter).distanceSquared;
        
        // Ensure points.last is the end pointing away from the center
        if (tailDist > headDist) {
          orientedStrips.add(Strip(
            id: strip.id,
            points: strip.points.reversed.toList(),
            width: strip.width,
            zIndex: strip.zIndex,
          ));
        } else {
          orientedStrips.add(strip);
        }
      } else {
        orientedStrips.add(strip);
      }
    }
    
    return orientedStrips;
  }

  static PuzzleLevel _buildLevel(int levelIndex) {
    switch (levelIndex) {
      case 1: return _buildLevel1();
      case 2: return _buildLevel2();
      case 3: return _buildLevel3();
      case 4: return _buildLevel4();
      case 5: return _buildLevel5();
      case 6: return _buildLevel6();
      case 7: return _buildLevel7();
      case 8: return _buildLevel8();
      case 9: return _buildLevel9();
      case 10: return _buildLevel10();
      case 11: return _buildLevel11();
      case 12: return _buildLevel12();
      case 13: return _buildLevel13();
      case 14: return _buildLevel14();
      case 15: return _buildLevel15();
      case 16: return _buildLevel16();
      case 17: return _buildLevel17();
      case 18: return _buildLevel18();
      case 19: return _buildLevel19();
      case 20: return _buildLevel20();
      case 21: return _buildLevel21();
      case 22: return _buildLevel22();
      default:
        // For now, if a higher level is requested, just return level 3 as a fallback
        return _buildLevel3().copyWith(levelId: 'level_$levelIndex');
    }
  }

  /// Calculates actual physical intersections between strips (polylines) to define dependencies.
  static List<Crossing> _calculateCrossings(List<Strip> strips) {
    final crossings = <Crossing>{}; // Use Set to avoid duplicate crossings between the same two strips
    
    for (int i = 0; i < strips.length; i++) {
      for (int j = i + 1; j < strips.length; j++) {
        final s1 = strips[i];
        final s2 = strips[j];
        
        bool intersect = false;
        
        // Check every segment of s1 against every segment of s2
        for (int k = 0; k < s1.points.length - 1; k++) {
          final p1 = s1.points[k];
          final p2 = s1.points[k + 1];
          
          for (int l = 0; l < s2.points.length - 1; l++) {
            final q1 = s2.points[l];
            final q2 = s2.points[l + 1];
            
            // Expanded intersection check using distance (to account for width)
            // Simplified: if the distance between the two segments is less than (w1+w2)/2
            if (_segmentDistance(p1, p2, q1, q2) < (s1.width + s2.width) / 2.0 * 0.9) {
              intersect = true;
              break;
            }
          }
          if (intersect) break;
        }

        if (intersect) {
          // They physically intersect! The one with higher zIndex is on top.
          if (s1.zIndex > s2.zIndex) {
            crossings.add(Crossing(upperStripId: s1.id, lowerStripId: s2.id));
          } else if (s2.zIndex > s1.zIndex) {
            crossings.add(Crossing(upperStripId: s2.id, lowerStripId: s1.id));
          }
        }
      }
    }
    return crossings.toList();
  }

  // --- Mathematics for Segment-to-Segment Distance ---
  static double _segmentDistance(Offset p1, Offset p2, Offset q1, Offset q2) {
    // 1. Check if segments intersect directly
    if (_doIntersect(p1, p2, q1, q2)) return 0.0;

    // 2. Minimum distance is the min of the distance from endpoints to the other segment
    final d1 = _pointToSegmentDist(p1, q1, q2);
    final d2 = _pointToSegmentDist(p2, q1, q2);
    final d3 = _pointToSegmentDist(q1, p1, p2);
    final d4 = _pointToSegmentDist(q2, p1, p2);
    return min(min(d1, d2), min(d3, d4));
  }

  static double _pointToSegmentDist(Offset p, Offset a, Offset b) {
    final l2 = (a.dx - b.dx) * (a.dx - b.dx) + (a.dy - b.dy) * (a.dy - b.dy);
    if (l2 == 0) return (p - a).distance;
    double t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / l2;
    t = max(0, min(1, t));
    final proj = Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy));
    return (p - proj).distance;
  }

  static bool _doIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
    int o1 = _orientation(p1, q1, p2);
    int o2 = _orientation(p1, q1, q2);
    int o3 = _orientation(p2, q2, p1);
    int o4 = _orientation(p2, q2, q1);
    if (o1 != o2 && o3 != o4) return true;
    return false;
  }

  static int _orientation(Offset p, Offset q, Offset r) {
    double val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
    if (val == 0) return 0; // collinear
    return (val > 0) ? 1 : 2; // clock or counterclock wise
  }

  // ============================================================================
  // PROOF LEVELS (MANUAL TOPOLOGICAL DESIGNS)
  // ============================================================================

  /// LEVEL 1: PRODUCTION ONBOARDING
  /// - Exactly 2 straight strips. A -> B.
  static PuzzleLevel _buildLevel1() {
    const double w = 40.0;
    final strips = const [
      // B: Vertical, centered, underneath A
      Strip(id: 'B', points: [Offset(500, 200), Offset(500, 800)], width: w, zIndex: 1),
      // A: Horizontal, centered, above B
      Strip(id: 'A', points: [Offset(200, 500), Offset(800, 500)], width: w, zIndex: 2),
    ];
    // A crosses B at (500, 500) -> A blocks B.
    // Valid moves: A, then B.

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_1',
      metadata: LevelMetadata(difficulty: 1, stripCount: 2, crossingCount: crossings.length, gridType: 'production_1'),
      strips: strips,
      crossings: crossings,
    );
  }



  /// LEVEL 2: PRODUCTION (CHAIN DEPENDENCY)
  /// - 3 straight strips. A -> B -> C.
  static PuzzleLevel _buildLevel2() {
    const double w = 40.0;
    final strips = const [
      // C: Horizontal, bottom
      Strip(id: 'C', points: [Offset(200, 700), Offset(800, 700)], width: w, zIndex: 1),
      // B: Vertical, middle
      Strip(id: 'B', points: [Offset(500, 200), Offset(500, 800)], width: w, zIndex: 2),
      // A: Horizontal, top
      Strip(id: 'A', points: [Offset(200, 300), Offset(800, 300)], width: w, zIndex: 3),
    ];
    // A crosses B at (500, 300) -> A blocks B
    // B crosses C at (500, 700) -> B blocks C

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_2',
      metadata: LevelMetadata(difficulty: 2, stripCount: 3, crossingCount: crossings.length, gridType: 'production_2'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 11: FIRST TRACE (Moved from old Level 2)
  /// - 4 strips, including 1 bent U-shape.
  /// - The bent strip is dominant at its head but blocked at its tail.
  static PuzzleLevel _buildLevel11() {
    const double w = 40.0;
    final strips = const [
      Strip(id: 'FLOOR', points: [Offset(300, 200), Offset(300, 800)], width: w, zIndex: 1),
      Strip(id: 'BENT', points: [Offset(200, 300), Offset(700, 300), Offset(700, 700), Offset(200, 700)], width: w, zIndex: 2),
      Strip(id: 'TRAP', points: [Offset(600, 200), Offset(600, 800)], width: w, zIndex: 3),
      Strip(id: 'KEY', points: [Offset(500, 400), Offset(800, 400)], width: w, zIndex: 4),
    ];
    // BENT crosses FLOOR at (300, 300) and (300, 700). BENT blocks FLOOR.
    // TRAP crosses BENT at (600, 300) and (600, 700). TRAP blocks BENT.
    // KEY crosses TRAP at (600, 400). KEY blocks TRAP.
    
    // Player might see the big BENT strip dominating FLOOR on the left, but if they tap it, it wiggles because TRAP holds it on the right.

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_11',
      metadata: LevelMetadata(difficulty: 3, stripCount: 4, crossingCount: crossings.length, gridType: 'proof_11'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 3: PRODUCTION (DOUBLE ANCHOR) [Replaced with Level 12]
  /// - 5 strips. One continuous bent strip (A) blocked by two independent straight strips (B, C).
  /// - B -> A, C -> A, A -> D, D -> E.
  static PuzzleLevel _buildLevel3() {
    const double w = 40.0;
    final strips = const [
      // E: Vertical, right-most base
      Strip(id: 'E', points: [Offset(700, 400), Offset(700, 800)], width: w, zIndex: 1),
      // D: Horizontal, supporting A and crossing E
      Strip(id: 'D', points: [Offset(400, 600), Offset(800, 600)], width: w, zIndex: 2),
      // A: L-shaped continuous bent strip
      Strip(id: 'A', points: [Offset(200, 300), Offset(500, 300), Offset(500, 700)], width: w, zIndex: 3),
      // C: Vertical, crossing the horizontal leg of A
      Strip(id: 'C', points: [Offset(300, 150), Offset(300, 450)], width: w, zIndex: 4),
      // B: Horizontal, crossing the vertical leg of A
      Strip(id: 'B', points: [Offset(400, 450), Offset(650, 450)], width: w, zIndex: 5),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_3',
      metadata: LevelMetadata(difficulty: 3, stripCount: 5, crossingCount: crossings.length, gridType: 'production_12'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 4: SPLIT DECISION [Replaced with Level 15]
  /// - 6 strips. One bent strip (A).
  /// - Dependency: A -> D, B -> D, A -> E, C -> E, D -> F, E -> F.
  /// - A, B, C are initially free.
  static PuzzleLevel _buildLevel4() {
    const double w = 32.0; // Reduced thickness significantly
    final strips = const [
      // F: Horizontal base strip at the bottom
      Strip(id: 'F', points: [Offset(210, 740), Offset(790, 740)], width: w, zIndex: 1),
      // D: Left vertical pillar
      Strip(id: 'D', points: [Offset(330, 260), Offset(330, 790)], width: w, zIndex: 2),
      // E: Right vertical pillar
      Strip(id: 'E', points: [Offset(670, 260), Offset(670, 790)], width: w, zIndex: 3),
      // A: Large L-shaped strip crossing both pillars
      Strip(id: 'A', points: [Offset(210, 520), Offset(790, 520), Offset(790, 210)], width: w, zIndex: 4),
      // B: Short horizontal strip crossing left pillar
      Strip(id: 'B', points: [Offset(210, 630), Offset(450, 630)], width: w, zIndex: 5),
      // C: Short horizontal strip crossing right pillar
      Strip(id: 'C', points: [Offset(550, 630), Offset(790, 630)], width: w, zIndex: 6),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_4',
      metadata: LevelMetadata(difficulty: 4, stripCount: 6, crossingCount: crossings.length, gridType: 'topological_15'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 5: PRODUCTION (SMALL DEPENDENCY NETWORK)
  /// - 5 straight strips. A -> B, B -> (C, D), (C, D) -> E.
  static PuzzleLevel _buildLevel5() {
    const double w = 40.0;
    final strips = const [
      // E: Vertical, right
      Strip(id: 'E', points: [Offset(650, 350), Offset(650, 850)], width: w, zIndex: 1),
      // D: Horizontal, bottom
      Strip(id: 'D', points: [Offset(250, 650), Offset(800, 650)], width: w, zIndex: 2),
      // C: Horizontal, middle
      Strip(id: 'C', points: [Offset(250, 450), Offset(800, 450)], width: w, zIndex: 3),
      // B: Vertical, left
      Strip(id: 'B', points: [Offset(350, 150), Offset(350, 750)], width: w, zIndex: 4),
      // A: Horizontal, top-left (doesn't reach E)
      Strip(id: 'A', points: [Offset(150, 250), Offset(500, 250)], width: w, zIndex: 5),
    ];
    // A crosses B at (350, 250) -> A blocks B
    // B crosses C at (350, 450) -> B blocks C
    // B crosses D at (350, 650) -> B blocks D
    // C crosses E at (650, 450) -> C blocks E
    // D crosses E at (650, 650) -> D blocks E

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_5',
      metadata: LevelMetadata(difficulty: 5, stripCount: 5, crossingCount: crossings.length, gridType: 'production_5'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 6: PRODUCTION (MULTIPLE INITIAL CHOICES)
  /// - 5 straight strips. A -> C, B -> C, C -> E, D -> E.
  static PuzzleLevel _buildLevel6() {
    const double w = 40.0;
    final strips = const [
      // E: Horizontal, bottom-right
      Strip(id: 'E', points: [Offset(300, 500), Offset(800, 500)], width: w, zIndex: 1),
      // D: Vertical, right
      Strip(id: 'D', points: [Offset(700, 400), Offset(700, 800)], width: w, zIndex: 2),
      // C: Vertical, left
      Strip(id: 'C', points: [Offset(400, 200), Offset(400, 700)], width: w, zIndex: 3),
      // B: Horizontal, bottom-left
      Strip(id: 'B', points: [Offset(200, 600), Offset(500, 600)], width: w, zIndex: 4),
      // A: Horizontal, top-left
      Strip(id: 'A', points: [Offset(200, 300), Offset(500, 300)], width: w, zIndex: 5),
    ];
    // A crosses C at (400, 300) -> A blocks C
    // B crosses C at (400, 600) -> B blocks C
    // C crosses E at (400, 500) -> C blocks E
    // D crosses E at (700, 500) -> D blocks E

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_6',
      metadata: LevelMetadata(difficulty: 6, stripCount: 5, crossingCount: crossings.length, gridType: 'production_6'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 7: PRODUCTION (CHOICE WITH CONSEQUENCE)
  /// - 6 straight strips. A -> C, B -> C, C -> E, D -> E, B -> F.
  static PuzzleLevel _buildLevel7() {
    const double w = 40.0;
    final strips = const [
      // F: Vertical, bottom-left
      Strip(id: 'F', points: [Offset(300, 550), Offset(300, 800)], width: w, zIndex: 1),
      // E: Horizontal, bottom-right
      Strip(id: 'E', points: [Offset(300, 500), Offset(800, 500)], width: w, zIndex: 2),
      // D: Vertical, right
      Strip(id: 'D', points: [Offset(700, 400), Offset(700, 800)], width: w, zIndex: 3),
      // C: Vertical, middle
      Strip(id: 'C', points: [Offset(400, 200), Offset(400, 700)], width: w, zIndex: 4),
      // B: Horizontal, middle-left
      Strip(id: 'B', points: [Offset(200, 600), Offset(500, 600)], width: w, zIndex: 5),
      // A: Horizontal, top-left
      Strip(id: 'A', points: [Offset(200, 300), Offset(500, 300)], width: w, zIndex: 6),
    ];
    // A crosses C at (400, 300) -> A blocks C
    // B crosses C at (400, 600) -> B blocks C
    // C crosses E at (400, 500) -> C blocks E
    // D crosses E at (700, 500) -> D blocks E
    // B crosses F at (300, 600) -> B blocks F

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_7',
      metadata: LevelMetadata(difficulty: 7, stripCount: 6, crossingCount: crossings.length, gridType: 'production_7'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 8: PRODUCTION (TWO BRANCHES, ONE MERGE)
  /// - 6 straight strips. A -> C, B -> C, D -> E, C -> F, E -> F.
  static PuzzleLevel _buildLevel8() {
    const double w = 40.0;
    final strips = const [
      // F: Horizontal, bottom
      Strip(id: 'F', points: [Offset(200, 650), Offset(800, 650)], width: w, zIndex: 1),
      // E: Vertical, right
      Strip(id: 'E', points: [Offset(650, 400), Offset(650, 800)], width: w, zIndex: 2),
      // D: Horizontal, middle-right
      Strip(id: 'D', points: [Offset(500, 500), Offset(800, 500)], width: w, zIndex: 3),
      // C: Vertical, left
      Strip(id: 'C', points: [Offset(350, 200), Offset(350, 800)], width: w, zIndex: 4),
      // B: Horizontal, middle-left
      Strip(id: 'B', points: [Offset(200, 450), Offset(500, 450)], width: w, zIndex: 5),
      // A: Horizontal, top-left
      Strip(id: 'A', points: [Offset(200, 300), Offset(500, 300)], width: w, zIndex: 6),
    ];
    // A crosses C at (350, 300) -> A blocks C
    // B crosses C at (350, 450) -> B blocks C
    // D crosses E at (650, 500) -> D blocks E
    // C crosses F at (350, 650) -> C blocks F
    // E crosses F at (650, 650) -> E blocks F

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_8',
      metadata: LevelMetadata(difficulty: 8, stripCount: 6, crossingCount: crossings.length, gridType: 'production_8'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 9: PRODUCTION (THREE-WAY FINAL LOCK)
  /// - 7 straight strips. A -> D, B -> D, C -> E, D -> F, E -> F, G -> F.
  static PuzzleLevel _buildLevel9() {
    const double w = 40.0;
    final strips = const [
      // F: Horizontal, bottom
      Strip(id: 'F', points: [Offset(200, 700), Offset(800, 700)], width: w, zIndex: 1),
      // G: Vertical, right
      Strip(id: 'G', points: [Offset(700, 500), Offset(700, 800)], width: w, zIndex: 2),
      // E: Vertical, middle
      Strip(id: 'E', points: [Offset(500, 400), Offset(500, 800)], width: w, zIndex: 3),
      // D: Vertical, left
      Strip(id: 'D', points: [Offset(300, 300), Offset(300, 800)], width: w, zIndex: 4),
      // C: Horizontal, middle
      Strip(id: 'C', points: [Offset(400, 550), Offset(600, 550)], width: w, zIndex: 5),
      // B: Horizontal, top-left (lower)
      Strip(id: 'B', points: [Offset(150, 500), Offset(400, 500)], width: w, zIndex: 6),
      // A: Horizontal, top-left (upper)
      Strip(id: 'A', points: [Offset(150, 400), Offset(400, 400)], width: w, zIndex: 7),
    ];
    // A crosses D at (300, 400) -> A blocks D
    // B crosses D at (300, 500) -> B blocks D
    // C crosses E at (500, 550) -> C blocks E
    // D crosses F at (300, 700) -> D blocks F
    // E crosses F at (500, 700) -> E blocks F
    // G crosses F at (700, 700) -> G blocks F

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_9',
      metadata: LevelMetadata(difficulty: 9, stripCount: 7, crossingCount: crossings.length, gridType: 'production_9'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 10: PRODUCTION (THE FIRST DENSE DEPENDENCY)
  /// - 8 straight strips. Milestone puzzle combining multiple branch rules.
  static PuzzleLevel _buildLevel10() {
    const double w = 40.0;
    final strips = const [
      // H: Vertical, right-most anchor
      Strip(id: 'H', points: [Offset(650, 500), Offset(650, 850)], width: w, zIndex: 1),
      // F: Horizontal, main base
      Strip(id: 'F', points: [Offset(150, 600), Offset(750, 600)], width: w, zIndex: 2),
      // E: Vertical, middle
      Strip(id: 'E', points: [Offset(350, 400), Offset(350, 650)], width: w, zIndex: 3),
      // D: Vertical, left
      Strip(id: 'D', points: [Offset(200, 300), Offset(200, 650)], width: w, zIndex: 4),
      // G: Diagonal, crossing F and H
      Strip(id: 'G', points: [Offset(450, 550), Offset(700, 800)], width: w, zIndex: 5),
      // C: Horizontal, controlling E
      Strip(id: 'C', points: [Offset(275, 500), Offset(425, 500)], width: w, zIndex: 6),
      // B: Horizontal, lower controlling D
      Strip(id: 'B', points: [Offset(100, 450), Offset(275, 450)], width: w, zIndex: 7),
      // A: Horizontal, upper controlling D
      Strip(id: 'A', points: [Offset(100, 350), Offset(275, 350)], width: w, zIndex: 8),
    ];
    // Crossings encoded:
    // A -> D
    // B -> D
    // C -> E
    // D -> F
    // E -> F
    // G -> F
    // F -> H
    // G -> H

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_10',
      metadata: LevelMetadata(difficulty: 10, stripCount: 8, crossingCount: crossings.length, gridType: 'production_10'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 12: PRODUCTION (DOUBLE ANCHOR)
  /// - 5 strips. One continuous bent strip (A) blocked by two independent straight strips (B, C).
  /// - B -> A, C -> A, A -> D, D -> E.
  static PuzzleLevel _buildLevel12() {
    const double w = 40.0;
    final strips = const [
      // E: Vertical, right-most base
      Strip(id: 'E', points: [Offset(700, 400), Offset(700, 800)], width: w, zIndex: 1),
      // D: Horizontal, supporting A and crossing E
      Strip(id: 'D', points: [Offset(400, 600), Offset(800, 600)], width: w, zIndex: 2),
      // A: L-shaped continuous bent strip
      Strip(id: 'A', points: [Offset(200, 300), Offset(500, 300), Offset(500, 700)], width: w, zIndex: 3),
      // C: Vertical, crossing the horizontal leg of A
      Strip(id: 'C', points: [Offset(300, 150), Offset(300, 450)], width: w, zIndex: 4),
      // B: Horizontal, crossing the vertical leg of A
      Strip(id: 'B', points: [Offset(400, 450), Offset(650, 450)], width: w, zIndex: 5),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_12',
      metadata: LevelMetadata(difficulty: 12, stripCount: 5, crossingCount: crossings.length, gridType: 'production_12'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 13: CONTROLLED TOPOLOGICAL PROGRESSION
  /// - 5 strips. One continuous bent strip (A).
  /// - Dependency: D -> A, D -> B, A -> C, B -> C, C -> E.
  /// - D is the only initial free strip.
  static PuzzleLevel _buildLevel13() {
    const double w = 40.0;
    final strips = const [
      // E: Short vertical strip on the far right
      Strip(id: 'E', points: [Offset(320, 520), Offset(320, 680)], width: w, zIndex: 1),
      // C: Horizontal strip at the bottom
      Strip(id: 'C', points: [Offset(60, 600), Offset(360, 600)], width: w, zIndex: 2),
      // B: Vertical strip on the left
      Strip(id: 'B', points: [Offset(100, 200), Offset(100, 680)], width: w, zIndex: 3),
      // A: L-shaped continuous bent strip on the right
      Strip(id: 'A', points: [Offset(180, 680), Offset(180, 425), Offset(260, 425), Offset(260, 200)], width: w, zIndex: 4),
      // D: Horizontal strip at the top, the only free strip
      Strip(id: 'D', points: [Offset(60, 250), Offset(300, 250)], width: w, zIndex: 5),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_13',
      metadata: LevelMetadata(difficulty: 13, stripCount: 5, crossingCount: crossings.length, gridType: 'topological_13'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 14: SECOND TOPOLOGICAL TRACE STEP
  /// - 5 strips. One continuous bent strip (A).
  /// - Dependency: E -> A, E -> B, A -> C, B -> C, C -> D.
  /// - E is the only initial free strip.
  static PuzzleLevel _buildLevel14() {
    const double w = 40.0;
    final strips = const [
      // D: Short vertical strip at the bottom center
      Strip(id: 'D', points: [Offset(180, 550), Offset(180, 680)], width: w, zIndex: 1),
      // C: Long horizontal strip at the bottom
      Strip(id: 'C', points: [Offset(60, 600), Offset(340, 600)], width: w, zIndex: 2),
      // B: Long vertical strip on the left
      Strip(id: 'B', points: [Offset(110, 200), Offset(110, 650)], width: w, zIndex: 3),
      // A: Bent strip on the right
      Strip(id: 'A', points: [Offset(250, 650), Offset(250, 425), Offset(310, 425), Offset(310, 200)], width: w, zIndex: 4),
      // E: Long horizontal strip at the top, the only free strip
      Strip(id: 'E', points: [Offset(60, 250), Offset(350, 250)], width: w, zIndex: 5),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_14',
      metadata: LevelMetadata(difficulty: 14, stripCount: 5, crossingCount: crossings.length, gridType: 'topological_14'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 15: SPLIT DECISION
  /// - 6 strips. One bent strip (A).
  /// - Dependency: A -> D, B -> D, A -> E, C -> E, D -> F, E -> F.
  /// - A, B, C are initially free.
  static PuzzleLevel _buildLevel15() {
    const double w = 40.0;
    final strips = const [
      // F: Horizontal base strip at the bottom
      Strip(id: 'F', points: [Offset(50, 680), Offset(340, 680)], width: w, zIndex: 1),
      // D: Left vertical pillar
      Strip(id: 'D', points: [Offset(110, 200), Offset(110, 730)], width: w, zIndex: 2),
      // E: Right vertical pillar
      Strip(id: 'E', points: [Offset(280, 200), Offset(280, 730)], width: w, zIndex: 3),
      // A: Large L-shaped strip crossing both pillars
      Strip(id: 'A', points: [Offset(50, 460), Offset(340, 460), Offset(340, 150)], width: w, zIndex: 4),
      // B: Short horizontal strip crossing left pillar
      Strip(id: 'B', points: [Offset(50, 570), Offset(170, 570)], width: w, zIndex: 5),
      // C: Short horizontal strip crossing right pillar
      Strip(id: 'C', points: [Offset(220, 570), Offset(340, 570)], width: w, zIndex: 6),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_15',
      metadata: LevelMetadata(difficulty: 15, stripCount: 6, crossingCount: crossings.length, gridType: 'topological_15'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 16: MODERATE DIFFICULTY REFINEMENT
  /// - 6 strips in a staggered grid.
  /// - Dependency chain: H1 -> (V1, V2) -> H2 -> V3 -> H3.
  /// - Only H1 is initially free. V1, V2, V3 act as visual traps.
  static PuzzleLevel _buildLevel16() {
    const double w = 40.0;
    final strips = const [
      // H3: Horizontal Bottom (Z=1)
      Strip(id: 'H3', points: [Offset(150, 500), Offset(350, 500)], width: w, zIndex: 1),
      // V3: Vertical Right (Z=2)
      Strip(id: 'V3', points: [Offset(300, 300), Offset(300, 550)], width: w, zIndex: 2),
      // H2: Horizontal Middle (Z=3)
      Strip(id: 'H2', points: [Offset(50, 350), Offset(350, 350)], width: w, zIndex: 3),
      // V1: Vertical Left (Z=4)
      Strip(id: 'V1', points: [Offset(100, 150), Offset(100, 400)], width: w, zIndex: 4),
      // V2: Vertical Middle (Z=5)
      Strip(id: 'V2', points: [Offset(200, 150), Offset(200, 550)], width: w, zIndex: 5),
      // H1: Horizontal Top (Z=6)
      Strip(id: 'H1', points: [Offset(50, 200), Offset(250, 200)], width: w, zIndex: 6),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_16',
      metadata: LevelMetadata(difficulty: 16, stripCount: 6, crossingCount: crossings.length, gridType: 'topological_16'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 17: TOPOLOGICAL DEPENDENCY
  /// - Introduces the first small connected geometry (`D_bent`).
  /// - Forces the player to trace the continuous strip to discover multi-point dependencies.
  static PuzzleLevel _buildLevel17() {
    const double w = 40.0;
    final strips = const [
      // F (H3): Horizontal Bottom (Z=3). Blocked by D_bent, E, and G.
      Strip(id: 'F', points: [Offset(200, 280), Offset(500, 280)], width: w, zIndex: 3),
      // D_bent: Small L-shape (Z=4). Blocked by C (vertical leg) and E (horizontal leg). Blocks F.
      Strip(id: 'D_bent', points: [Offset(250, 180), Offset(250, 300), Offset(380, 300)], width: w, zIndex: 4),
      // C (H2): Mid Horizontal (Z=5). Blocked by B. Blocks D_bent.
      Strip(id: 'C', points: [Offset(100, 220), Offset(300, 220)], width: w, zIndex: 5),
      // G (V3): Right Vertical (Z=6). Blocked by A. Blocks F.
      Strip(id: 'G', points: [Offset(450, 50), Offset(450, 400)], width: w, zIndex: 6),
      // E (V2): Middle Vertical (Z=6). Blocked by A. Blocks D_bent and F.
      Strip(id: 'E', points: [Offset(350, 50), Offset(350, 400)], width: w, zIndex: 6),
      // B (V1): Left Vertical (Z=6). Blocked by A. Blocks C.
      Strip(id: 'B', points: [Offset(150, 50), Offset(150, 300)], width: w, zIndex: 6),
      // A (H1): Top Horizontal (Z=7). ONLY FREE STRIP. Blocks B, E, G.
      Strip(id: 'A', points: [Offset(100, 100), Offset(500, 100)], width: w, zIndex: 7),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_17',
      metadata: LevelMetadata(difficulty: 17, stripCount: 7, crossingCount: crossings.length, gridType: 'topological_17'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 18: HARDER TOPOLOGICAL TRACING (SPACED LAYOUT)
  /// - Introduces deep branching with visually distinct zones.
  /// - Minimal clutter, wide spacing, requiring player to track parallel branches.
  static PuzzleLevel _buildLevel18() {
    const double w = 40.0;
    final strips = const [
      // G (Bottom-Left V, Z=5). Blocked by F.
      Strip(id: 'G', points: [Offset(100, 300), Offset(100, 450)], width: w, zIndex: 5),
      // F (Bottom H, Z=6). Deep multi-dependency trap. Blocked by D and E. Blocks G.
      Strip(id: 'F', points: [Offset(50, 350), Offset(450, 350)], width: w, zIndex: 6),
      // E (Left L-shape, Z=7). Blocked by B (H-leg) and C (V-leg). Blocks F.
      Strip(id: 'E', points: [Offset(50, 150), Offset(200, 150), Offset(200, 400)], width: w, zIndex: 7),
      // D (Far Right V, Z=8). Blocked by A. Blocks F.
      Strip(id: 'D', points: [Offset(450, 50), Offset(450, 450)], width: w, zIndex: 8),
      // C (Right L-shape, Z=8). Blocked by A. Blocks E's V-leg.
      Strip(id: 'C', points: [Offset(350, 50), Offset(350, 250), Offset(200, 250)], width: w, zIndex: 8),
      // B (Top-Left V, Z=8). Blocked by A. Blocks E's H-leg.
      Strip(id: 'B', points: [Offset(100, 50), Offset(100, 250)], width: w, zIndex: 8),
      // A (Top H, Z=9). ONLY FREE STRIP. Blocks B, C, D.
      Strip(id: 'A', points: [Offset(50, 100), Offset(450, 100)], width: w, zIndex: 9),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_18',
      metadata: LevelMetadata(difficulty: 18, stripCount: 7, crossingCount: crossings.length, gridType: 'topological_spaced_18'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 19: ADVANCED TOPOLOGICAL TRACING
  /// - Strict all-pairs validated segments.
  /// - Branching and convergence with no unintended overlaps.
  static PuzzleLevel _buildLevel19() {
    const double w = 40.0;
    final strips = const [
      Strip(id: 'A', points: [Offset(90, 50), Offset(580, 50)], width: w, zIndex: 9),
      Strip(id: 'B', points: [Offset(120, 30), Offset(120, 200)], width: w, zIndex: 8),
      Strip(id: 'C', points: [Offset(250, 30), Offset(250, 250), Offset(180, 250)], width: w, zIndex: 8),
      Strip(id: 'D', points: [Offset(400, 30), Offset(400, 480)], width: w, zIndex: 8),
      Strip(id: 'C2', points: [Offset(500, 30), Offset(500, 550)], width: w, zIndex: 8),
      Strip(id: 'E', points: [Offset(90, 150), Offset(200, 150), Offset(200, 550)], width: w, zIndex: 7),
      Strip(id: 'F', points: [Offset(230, 100), Offset(350, 100), Offset(350, 300), Offset(450, 300), Offset(450, 550)], width: w, zIndex: 7),
      Strip(id: 'G', points: [Offset(150, 500), Offset(550, 500)], width: w, zIndex: 6),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_19',
      metadata: LevelMetadata(difficulty: 19, stripCount: 8, crossingCount: crossings.length, gridType: 'topological_19'),
      strips: strips,
      crossings: crossings,
    );
  }

  /// LEVEL 20: FINAL HARD TOPOLOGICAL KNOT
  /// - 5 strips (Image-based knot).
  /// - Exactly one initial free strip (S_V1).
  /// - Deep interlocking dependency chain.
  static PuzzleLevel _buildLevel20() {
    const double w = 40.0;
    final strips = const [
      Strip(id: 'S_HTOP', points: [Offset(40, 180), Offset(200, 180)], width: w, zIndex: 1),
      Strip(id: 'S_V2', points: [Offset(180, 80), Offset(180, 560), Offset(260, 560)], width: w, zIndex: 2),
      Strip(id: 'S_HMAIN', points: [Offset(40, 240), Offset(360, 240)], width: w, zIndex: 3),
      Strip(id: 'S_V3', points: [Offset(300, 80), Offset(300, 340), Offset(100, 340)], width: w, zIndex: 4),
      Strip(id: 'S_V1', points: [Offset(120, 80), Offset(120, 500), Offset(360, 500)], width: w, zIndex: 5),
    ];

    final crossings = _calculateCrossings(strips);
    return PuzzleLevel(
      levelId: 'level_20',
      metadata: LevelMetadata(difficulty: 20, stripCount: 5, crossingCount: crossings.length, gridType: 'topological_20'),
      strips: strips,
      crossings: crossings,
    );
  }

  static PuzzleLevel _buildLevel21() {
    final strips = [
      Strip(id: 'S_TOP', points: [Offset(60, 150), Offset(340, 150)], width: 40.0, zIndex: 70),
      Strip(id: 'S_DIAG_UL', points: [Offset(150, 130), Offset(90, 370)], width: 40.0, zIndex: 60),
      Strip(id: 'S_DIAG_UR', points: [Offset(250, 130), Offset(310, 370)], width: 40.0, zIndex: 55),
      Strip(id: 'S_V_UPPER', points: [Offset(200, 130), Offset(200, 370)], width: 40.0, zIndex: 50),
      Strip(id: 'S_MID', points: [Offset(20, 350), Offset(380, 350)], width: 40.0, zIndex: 40),
      Strip(id: 'S_OUTER_L', points: [Offset(100, 130), Offset(20, 380), Offset(200, 680)], width: 40.0, zIndex: 30),
      Strip(id: 'S_OUTER_R', points: [Offset(300, 130), Offset(380, 380), Offset(200, 680)], width: 40.0, zIndex: 20),
    ];

    final crossings = _calculateCrossings(strips);

    return PuzzleLevel(
      levelId: 'level_21',
      strips: strips,
      crossings: crossings,
      metadata: LevelMetadata(difficulty: 21, stripCount: strips.length, crossingCount: crossings.length),
    );
  }

  static PuzzleLevel _buildLevel22() {
    const double w = 37.0;

    final strips = [
      // Outer Ring
      Strip(id: 'S4', points: [Offset(200, 150), Offset(200, 850)], width: w, zIndex: 130), // V Left
      Strip(id: 'S1', points: [Offset(150, 200), Offset(850, 200)], width: w, zIndex: 120), // H Top
      Strip(id: 'S2', points: [Offset(800, 150), Offset(800, 850)], width: w, zIndex: 110), // V Right
      Strip(id: 'S3', points: [Offset(150, 800), Offset(850, 800)], width: w, zIndex: 100), // H Bottom

      // Inner Ring
      Strip(id: 'S8', points: [Offset(350, 150), Offset(350, 850)], width: w, zIndex: 90), // V Left-Mid
      Strip(id: 'S5', points: [Offset(150, 350), Offset(850, 350)], width: w, zIndex: 80), // H Top-Mid
      Strip(id: 'S6', points: [Offset(650, 150), Offset(650, 850)], width: w, zIndex: 70), // V Right-Mid
      Strip(id: 'S7', points: [Offset(150, 650), Offset(850, 650)], width: w, zIndex: 60), // H Bottom-Mid

      // Center Hash (Spaced tight-zone)
      Strip(id: 'S9', points: [Offset(465, 250), Offset(465, 750)], width: w, zIndex: 50), // V Left-Center
      Strip(id: 'S11', points: [Offset(250, 465), Offset(750, 465)], width: w, zIndex: 40), // H Top-Center
      Strip(id: 'S10', points: [Offset(535, 250), Offset(535, 750)], width: w, zIndex: 30), // V Right-Center
      Strip(id: 'S12', points: [Offset(250, 535), Offset(750, 535)], width: w, zIndex: 10), // H Bottom-Center

      // The Lock
      Strip(id: 'S13', points: [Offset(390, 390), Offset(610, 390), Offset(610, 610)], width: w, zIndex: 20), // L-shape
    ];

    final crossings = _calculateCrossings(strips);

    return PuzzleLevel(
      levelId: 'level_22',
      strips: strips,
      crossings: crossings,
      metadata: LevelMetadata(difficulty: 22, stripCount: strips.length, crossingCount: crossings.length, dependencyDepth: 13),
    );
  }
}
