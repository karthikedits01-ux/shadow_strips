import 'package:equatable/equatable.dart';

class LevelMetadata extends Equatable {
  final int difficulty; // 1-100+
  final int stripCount;
  final int crossingCount;
  final int deceptiveCrossingCount;
  final int branchingFactor; // approx number of concurrent free strips
  final int dependencyDepth; // longest path in the DAG
  
  final String gridType; // e.g., 'symmetric_3x3', 'asymmetric_4x5'
  final int? maxMistakes; // constraint limit (defaults to 3 in controller if null)
  final bool hasHiddenStrips; // introduces hidden mechanic

  const LevelMetadata({
    required this.difficulty,
    required this.stripCount,
    required this.crossingCount,
    this.deceptiveCrossingCount = 0,
    this.branchingFactor = 1,
    this.dependencyDepth = 1,
    this.gridType = 'symmetric_3x3',
    this.maxMistakes,
    this.hasHiddenStrips = false,
  });

  @override
  List<Object?> get props => [
        difficulty,
        stripCount,
        crossingCount,
        deceptiveCrossingCount,
        branchingFactor,
        dependencyDepth,
        gridType,
        maxMistakes,
        hasHiddenStrips,
      ];
}
