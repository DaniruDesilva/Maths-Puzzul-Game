import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';

class AdService {
  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static const int _maxFailedLoadAttempts = 3;
  static int _numRewardedLoadAttempts = 0;
  static int _numInterstitialLoadAttempts = 0;

  static const String _releaseRewardedId = '<YOUR_REWARDED_AD_UNIT_ID>';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static String get rewardedAdUnitId {
    if (kReleaseMode && !_releaseRewardedId.startsWith('<YOUR_')) {
      return _releaseRewardedId;
    }
    return _testRewardedId;
  }

  static const String _releaseInterstitialId = '<YOUR_INTERSTITIAL_AD_UNIT_ID>';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static String get interstitialAdUnitId {
    if (kReleaseMode && !_releaseInterstitialId.startsWith('<YOUR_')) {
      return _releaseInterstitialId;
    }
    return _testInterstitialId;
  }

  static void initialize() {
    try {
      MobileAds.instance.initialize();
      _createRewardedAd();
      _createInterstitialAd();
    } catch (e) {
      debugPrint('AdService initialization error: $e');
    }
  }

  static void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
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

  static void showRewardedAd(UserProvider user, {VoidCallback? onReward, VoidCallback? onDismissed}) {
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded before loaded.');
      _createRewardedAd();
      if (!kReleaseMode) {
        // Safe development & test fallback to ensure reward workflows work without live ad servers
        if (onReward != null) {
          onReward();
        } else {
          user.addHint();
        }
      }
      onDismissed?.call();
      return;
    }
    
    bool userEarnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) => debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _createRewardedAd(); // Load next ad
        if (userEarnedReward) {
          if (onReward != null) {
            onReward();
          } else {
            user.addHint();
          }
        }
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _createRewardedAd();
        onDismissed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        userEarnedReward = true;
      },
    );
    _rewardedAd = null;
  }

  static void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
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
