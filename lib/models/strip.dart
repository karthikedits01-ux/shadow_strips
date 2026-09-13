import 'dart:ui';
import 'package:equatable/equatable.dart';

/// The fundamental states of a strip in the puzzle.
///
/// [locked]   - The strip is underneath another strip and cannot be removed.
/// [free]     - The strip has no dependencies and is ready to be tapped.
/// [removing] - The strip is currently animating out of the board.
///              Input is locked during this state.
/// [removed]  - The strip is fully extracted and no longer on the board.
enum StripState {
  locked,
  free,
  removing,
  removed,
}

/// A logical puzzle strip.
///
/// Strips are positioned logically based on a list of points
/// representing a continuous polyline.
/// This prevents hardcoded pixel values and allows bent geometry.
class Strip extends Equatable {
  final String id;
  final List<Offset> points;
  final double width;
  
  /// Intended visual rendering z-index. Higher values render later (on top).
  final int zIndex;

  const Strip({
    required this.id,
    required this.points,
    required this.width,
    required this.zIndex,
  });

  @override
  List<Object?> get props => [
        id,
        points,
        width,
        zIndex,
      ];
}
