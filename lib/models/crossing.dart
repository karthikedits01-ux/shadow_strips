import 'package:equatable/equatable.dart';

enum ShadowMode {
  normal,
  deceptive,
}

/// Represents a directed dependency between two strips.
///
/// A crossing implies that [upperStripId] physically lies above [lowerStripId]
/// at some intersection point, meaning [upperStripId] MUST be extracted
/// before [lowerStripId] can become free.
///
/// Direction: upperStripId -> lowerStripId
class Crossing extends Equatable {
  final String upperStripId;
  final String lowerStripId;
  final ShadowMode shadowMode;

  const Crossing({
    required this.upperStripId,
    required this.lowerStripId,
    this.shadowMode = ShadowMode.normal,
  });

  @override
  List<Object?> get props => [upperStripId, lowerStripId, shadowMode];
}

