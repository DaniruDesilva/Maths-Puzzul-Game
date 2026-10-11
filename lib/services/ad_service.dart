import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';

class AdService {
  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static const int _maxFailedLoadAttempts = 3;
  static int _numRewardedLoadAttempts = 0;
  static int _numInterstitialLoadAttempts = 0;

  static void initialize() {
    MobileAds.instance.initialize();
    _createRewardedAd();
    _createInterstitialAd();
  }

  static void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: kReleaseMode ? '<YOUR_REWARDED_AD_UNIT_ID>' : 'ca-app-pub-3940256099942544/5224354917', // Test ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts < _maxFailedLoadAttempts) {
            _createRewardedAd();
          }
        },
      ),
    );
  }

  static void showRewardedAd(UserProvider user) {
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded before loaded.');
      _createRewardedAd();
      return;
    }
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) => debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _createRewardedAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // User earned reward
        user.addHint();
      },
    );
    _rewardedAd = null;
  }

  static void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: kReleaseMode ? '<YOUR_INTERSTITIAL_AD_UNIT_ID>' : 'ca-app-pub-3940256099942544/1033173712', // Test ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _numInterstitialLoadAttempts += 1;
          if (_numInterstitialLoadAttempts < _maxFailedLoadAttempts) {
            _createInterstitialAd();
          }
        },
      ),
    );
  }

  static DateTime? _lastInterstitialTime;
  static const Duration _interstitialCooldown = Duration(seconds: 120);

  static void showInterstitialAd(VoidCallback onAdDismissed, {int currentLevel = 11}) {
    // 10-level grace period for new players to establish flow & retention
    if (currentLevel <= 10) {
      onAdDismissed();
      return;
    }

    // 120-second minimum cooldown between full-screen ads
    final now = DateTime.now();
    if (_lastInterstitialTime != null &&
        now.difference(_lastInterstitialTime!) < _interstitialCooldown) {
      onAdDismissed();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      _createInterstitialAd();
      onAdDismissed();
      return;
    }

    _lastInterstitialTime = now;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _createInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _createInterstitialAd();
        onAdDismissed();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
