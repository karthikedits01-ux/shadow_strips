import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_strips/logic/dependency_graph.dart';
import 'package:shadow_strips/logic/level_repository.dart';
import 'package:shadow_strips/models/game_state.dart';
import 'package:shadow_strips/models/strip.dart';
import 'package:shadow_strips/rendering/puzzle_painter.dart';

void main() {
  test('Render Level 22 Default View Screenshot', () async {
    final level = LevelRepository.getLevel('level_22');
    final graph = DependencyGraph.fromCrossings(level.strips, level.crossings);
    final drawOrder = graph.getTopologicalDrawOrder();

    final stripStates = {for (var s in level.strips) s.id: StripState.free};
    final activeStrips = {for (var s in level.strips) s.id: s};

    final state = GameState(
      levelId: 'level_22',
      stripStates: stripStates,
      activeStrips: activeStrips,
      drawOrder: drawOrder,
      mistakes: 0,
      isComplete: false,
      isGameOver: false,
    );

    // Standard phone screen resolution: 390 x 844
    const double width = 390;
    const double height = 844;
    final size = const Size(width, height);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Fill background with clean white
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    final painter = PuzzlePainter(
      state: state,
      level: level,
      logicalWidth: level.logicalWidth,
      logicalHeight: level.logicalHeight,
      removalAnimations: const {},
      errorAnimations: const {},
      safeAreaTop: 44.0,
      safeAreaBottom: 34.0,
    );

    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final artifactDir = Directory(r'C:\Users\Intel\.gemini\antigravity-ide\brain\7a86ba3f-e0d6-4fd5-a0ae-239b56760594');
    if (!artifactDir.existsSync()) {
      artifactDir.createSync(recursive: true);
    }
    final file = File(r'C:\Users\Intel\.gemini\antigravity-ide\brain\7a86ba3f-e0d6-4fd5-a0ae-239b56760594\level_22_default_view.png');
    await file.writeAsBytes(pngBytes);
    // ignore: avoid_print
    print('Screenshot successfully saved to: ${file.path}');
  });
}
