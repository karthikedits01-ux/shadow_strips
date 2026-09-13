import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  late final SharedPreferences _prefs;

  // Keys
  static const String _highestUnlockedKey = 'highestUnlockedLevel';
  static const String _completedLevelsKey = 'completedLevels';
  static const String _currentLevelKey = 'currentLevel';
  static const String _soundEnabledKey = 'soundEnabled';
  static const String _hapticsEnabledKey = 'hapticsEnabled';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize defaults if they don't exist
    if (!_prefs.containsKey(_highestUnlockedKey)) {
      await _prefs.setString(_highestUnlockedKey, 'level_1');
    }
    if (!_prefs.containsKey(_currentLevelKey)) {
      await _prefs.setString(_currentLevelKey, 'level_1');
    }
    if (!_prefs.containsKey(_soundEnabledKey)) {
      await _prefs.setBool(_soundEnabledKey, true);
    }
    if (!_prefs.containsKey(_hapticsEnabledKey)) {
      await _prefs.setBool(_hapticsEnabledKey, true);
    }
    if (!_prefs.containsKey(_completedLevelsKey)) {
      await _prefs.setStringList(_completedLevelsKey, []);
    }
  }

  // Current Level
  String get currentLevel => _prefs.getString(_currentLevelKey) ?? 'level_1';
  Future<void> setCurrentLevel(String levelId) async {
    await _prefs.setString(_currentLevelKey, levelId);
  }

  // Highest Unlocked Level
  String get highestUnlockedLevel => _prefs.getString(_highestUnlockedKey) ?? 'level_1';
  Future<void> setHighestUnlockedLevel(String levelId) async {
    await _prefs.setString(_highestUnlockedKey, levelId);
  }

  // Completed Levels
  List<String> get completedLevels => _prefs.getStringList(_completedLevelsKey) ?? [];
  Future<void> saveLevelComplete(String levelId, int mistakes) async {
    final completed = completedLevels;
    if (!completed.contains(levelId)) {
      completed.add(levelId);
      await _prefs.setStringList(_completedLevelsKey, completed);
    }
    
    // We should unlock next level automatically. This is usually handled by FlowController,
    // but the actual persist is here.
  }

  // Settings
  bool get isSoundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;
  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_soundEnabledKey, value);
  }

  bool get isHapticsEnabled => _prefs.getBool(_hapticsEnabledKey) ?? true;
  Future<void> setHapticsEnabled(bool value) async {
    await _prefs.setBool(_hapticsEnabledKey, value);
  }

  // Reset Progress (Keep settings intact)
  Future<void> resetProgress() async {
    await _prefs.setString(_highestUnlockedKey, 'level_1');
    await _prefs.setString(_currentLevelKey, 'level_1');
    await _prefs.setStringList(_completedLevelsKey, []);
  }
}
