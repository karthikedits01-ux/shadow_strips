import 'package:flutter/foundation.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  debugPrint('Level 1 strips: ${LevelRepository.getLevel('level_1').strips.length}');
  debugPrint('Level 2 strips: ${LevelRepository.getLevel('level_2').strips.length}');
  debugPrint('Level 4 strips: ${LevelRepository.getLevel('level_4').strips.length}');
  debugPrint('Level 5 strips: ${LevelRepository.getLevel('level_5').strips.length}');
}
