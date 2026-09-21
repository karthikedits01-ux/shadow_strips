import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  print('Level 1 strips: ${LevelRepository.getLevel('level_1').strips.length}');
  print('Level 2 strips: ${LevelRepository.getLevel('level_2').strips.length}');
  print('Level 4 strips: ${LevelRepository.getLevel('level_4').strips.length}');
  print('Level 5 strips: ${LevelRepository.getLevel('level_5').strips.length}');
}
