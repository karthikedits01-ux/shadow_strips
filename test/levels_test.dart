import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/level_repository.dart';

void main() {
  test('Levels return correctly', () {
    final l1 = LevelRepository.getLevel('level_1');
    final l2 = LevelRepository.getLevel('level_2');
    final l3 = LevelRepository.getLevel('level_3');
    final l4 = LevelRepository.getLevel('level_4');
    final l5 = LevelRepository.getLevel('level_5');

    print('Level 1: ${l1.strips.length} strips');
    print('Level 2: ${l2.strips.length} strips');
    print('Level 3: ${l3.strips.length} strips');
    print('Level 4: ${l4.strips.length} strips');
    print('Level 5: ${l5.strips.length} strips');

    expect(l1.strips.length, 2);
    expect(l2.strips.length, 3);
    expect(l3.strips.length, 5); // 12
    expect(l4.strips.length, 6); // 15
    expect(l5.strips.length, 5);
  });
}
