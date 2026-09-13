import 'package:equatable/equatable.dart';

class ShadowConfig extends Equatable {
  final double opacity;
  final double blurRadius;
  final double dx;
  final double dy;

  const ShadowConfig({
    this.opacity = 0.3,
    this.blurRadius = 10.0,
    this.dx = 5.0,
    this.dy = 10.0,
  });

  @override
  List<Object?> get props => [opacity, blurRadius, dx, dy];
}
