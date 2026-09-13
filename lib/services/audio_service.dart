import 'progress_service.dart';

/// Abstraction for audio feedback. 
/// Designed to fail gracefully and operate independently of gameplay logic.
class AudioService {
  final ProgressService _progressService;
  bool _isInitialized = false;

  AudioService(this._progressService);

  Future<void> initialize() async {
    // Intentionally left minimal to avoid blocking gameplay logic.
    // In production, this would load assets securely.
    _isInitialized = true;
  }

  Future<void> playExtractionSuccess() async {
    if (!_isInitialized || !_progressService.isSoundEnabled) return;
    // Play success sound
  }

  Future<void> playLockedResistance() async {
    if (!_isInitialized || !_progressService.isSoundEnabled) return;
    // Play locked sound
  }
  
  Future<void> playLevelComplete() async {
    if (!_isInitialized || !_progressService.isSoundEnabled) return;
    // Play complete sound
  }

  void dispose() {
    _isInitialized = false;
  }
}
