import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'controllers/game_controller.dart';
import 'controllers/flow_controller.dart';
import 'services/audio_service.dart';
import 'services/progress_service.dart';
import 'services/haptic_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make status bar transparent for a cleaner look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  final progressService = ProgressService();
  await progressService.initialize();

  final audioService = AudioService(progressService);
  await audioService.initialize();
  
  final hapticService = HapticService(progressService);

  final gameController = GameController(
    audioService: audioService,
    hapticService: hapticService,
  );

  final flowController = FlowController(
    progressService: progressService,
    gameController: gameController,
  );

  // Start the flow
  flowController.start();

  runApp(ShadowStripsApp(flowController: flowController));
}
