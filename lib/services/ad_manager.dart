import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;

  // Use test ID for Android. In a real app, you would switch based on platform and release mode.
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID

  bool get isAdLoaded => _isAdLoaded;

  void loadRewardedAd() {
    if (_isAdLoaded || _isAdLoading) return;
    
    _isAdLoading = true;
    
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded successfully');
          _rewardedAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
          _isAdLoaded = false;
          _isAdLoading = false;
        },
      ),
    );
  }

  void showRewardedAd({required VoidCallback onRewardEarned, VoidCallback? onAdClosed}) {
    if (_rewardedAd == null || !_isAdLoaded) {
      debugPrint('Warning: Attempted to show rewarded ad before it was loaded.');
      // If the ad isn't loaded for some reason, we can either retry or just grant the reward.
      // For a seamless UX in case of network failure, we could grant the reward, or just fail silently.
      onAdClosed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed fullscreen content.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        onAdClosed?.call();
        // Pre-load the next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        onAdClosed?.call();
        // Try to load another one
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      onRewardEarned();
    });
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    _isAdLoading = false;
  }
}
