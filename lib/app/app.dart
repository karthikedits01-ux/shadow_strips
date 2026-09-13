import 'package:flutter/material.dart';
import '../controllers/flow_controller.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/level_select_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/settings_screen.dart';

class ShadowStripsApp extends StatelessWidget {
  final FlowController flowController;

  const ShadowStripsApp({super.key, required this.flowController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow Strips',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        fontFamily: 'Roboto', // Simple clean font fallback
      ),
      home: ListenableBuilder(
        listenable: flowController,
        builder: (context, _) {
          switch (flowController.currentState) {
            case AppState.loading:
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF1C1C1E))));
            case AppState.home:
              return HomeScreen(flowController: flowController);
            case AppState.game:
              return GameScreen(flowController: flowController);
            case AppState.levels:
              return LevelSelectScreen(flowController: flowController);
            case AppState.daily:
              return DailyChallengeScreen(flowController: flowController);
            case AppState.settings:
              return SettingsScreen(flowController: flowController);
          }
        },
      ),
    );
  }
}
