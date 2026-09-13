import 'package:flutter/foundation.dart';
import '../services/progress_service.dart';
import '../logic/level_repository.dart';
import 'game_controller.dart';

enum AppState { loading, home, game, levels, daily, settings }

class FlowController extends ChangeNotifier {
  final ProgressService progressService;
  final GameController gameController;

  AppState _currentState = AppState.loading;
  AppState get currentState => _currentState;

  FlowController({
    required this.progressService,
    required this.gameController,
  }) {
    // Listen to game controller events
    gameController.onLevelComplete = _handleLevelComplete;
    gameController.onMistakesExceeded = _handleMistakesExceeded;
  }

  void start() {
    // Load the user's current level so resumeGame() works, but boot into the home screen
    final level = LevelRepository.getLevel(progressService.currentLevel);
    gameController.loadLevel(level);
    goHome();
  }

  void _launchLevel(String levelId) {
    progressService.setCurrentLevel(levelId);
    final level = LevelRepository.getLevel(levelId);
    gameController.loadLevel(level);
    _currentState = AppState.game;
    notifyListeners();
  }

  void goHome() {
    _currentState = AppState.home;
    notifyListeners();
  }

  void resumeGame() {
    _currentState = AppState.game;
    notifyListeners();
  }

  void goLevels() {
    _currentState = AppState.levels;
    notifyListeners();
  }
  
  void goDaily() {
    _currentState = AppState.daily;
    notifyListeners();
  }

  void goSettings() {
    _currentState = AppState.settings;
    notifyListeners();
  }

  void playLevel(String levelId) {
    _launchLevel(levelId);
  }

  void resetCurrentLevel() {
    _launchLevel(progressService.currentLevel);
  }

  void _handleMistakesExceeded() {
    // The GameScreen UI will now show a Game Over overlay.
    // We wait for the user to tap "Try Again" to call resetCurrentLevel().
  }

  void _handleLevelComplete() {
    progressService.saveLevelComplete(progressService.currentLevel, gameController.state.mistakes);
    
    // Determine next level (hardcoded logic for now, in a real game we parse numbers)
    final numStr = progressService.currentLevel.split('_').last;
    final currentNum = int.tryParse(numStr) ?? 1;
    final nextLevelId = 'level_${currentNum + 1}';
    
    // Ensure we track highest unlocked
    final highestNumStr = progressService.highestUnlockedLevel.split('_').last;
    final highestNum = int.tryParse(highestNumStr) ?? 1;
    if (currentNum + 1 > highestNum) {
      progressService.setHighestUnlockedLevel(nextLevelId);
    }
    
    // We do NOT automatically transition anymore. The UI will show an overlay
    // and call loadNextLevel() when the user taps "Next Game".
  }

  void loadNextLevel() {
    final numStr = progressService.currentLevel.split('_').last;
    final currentNum = int.tryParse(numStr) ?? 1;
    final nextLevelId = 'level_${currentNum + 1}';
    
    try {
      _launchLevel(nextLevelId);
    } catch (e) {
      _launchLevel('level_1');
    }
  }
}
