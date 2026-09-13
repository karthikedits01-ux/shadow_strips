import 'package:flutter/services.dart';
import 'progress_service.dart';

class HapticService {
  final ProgressService _progressService;

  HapticService(this._progressService);

  Future<void> lightImpact() async {
    if (!_progressService.isHapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> heavyImpact() async {
    if (!_progressService.isHapticsEnabled) return;
    await HapticFeedback.heavyImpact();
  }
}
