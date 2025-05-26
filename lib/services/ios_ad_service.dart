import 'package:unity_ads_plugin/unity_ads_plugin.dart';

class IOSAdService {
  static const String _gameId = '5859176';
  static const String _rewardedAdPlacementId = 'Rewarded_iOS';
  static const String _interstitialAdPlacementId = 'Interstitial_iOS';
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await UnityAds.init(
        gameId: _gameId,
        onComplete: () => _isInitialized = true,
        onFailed: (error, message) =>
            print('Unity Ads initialization failed: $message'),
      );
    }
  }

  Future<bool> showRewardedAd() async {
    if (!_isInitialized) {
      print('Unity Ads not initialized');
      return false;
    }

    try {
      await UnityAds.showVideoAd(
        placementId: _rewardedAdPlacementId,
        onComplete: (placementId) => print('Rewarded ad completed'),
        onFailed: (placementId, error, message) =>
            print('Rewarded ad failed: $message'),
        onStart: (placementId) => print('Rewarded ad started'),
        onSkipped: (placementId) => print('Rewarded ad skipped'),
      );
      return true;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  Future<bool> showInterstitialAd() async {
    if (!_isInitialized) {
      print('Unity Ads not initialized');
      return false;
    }

    try {
      await UnityAds.showVideoAd(
        placementId: _interstitialAdPlacementId,
        onComplete: (placementId) => print('Interstitial ad completed'),
        onFailed: (placementId, error, message) =>
            print('Interstitial ad failed: $message'),
        onStart: (placementId) => print('Interstitial ad started'),
        onSkipped: (placementId) => print('Interstitial ad skipped'),
      );
      return true;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }
}
