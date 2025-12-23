import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService with WidgetsBindingObserver {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;
  DateTime? _appOpenLoadTime;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  // Callbacks
  VoidCallback? onAppOpenAdLoaded;

  // Getters for UI
  bool get isRewardedAdReady => _rewardedAd != null;
  bool get isAppOpenAdReady => _appOpenAd != null;

  // Test IDs for Android (Swap with real IDs in production)
  static const String _appOpenTestId = 'ca-app-pub-3940256099942544/9257395923';
  static const String _interstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedTestId =
      'ca-app-pub-3940256099942544/5224354917';

  Future<void> init() async {
    await MobileAds.instance.initialize();
    WidgetsBinding.instance.addObserver(this);
    _loadAppOpenAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // --- App Open Ad Logic ---

  void _loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _appOpenTestId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd Loaded!');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          onAppOpenAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  // Check if ad is still valid (must be < 4 hours old)
  bool _isAdAvailable() {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
  }

  void showAppOpenAd() {
    if (!_isAdAvailable()) {
      debugPrint('AppOpenAd not ready or expired, trying to load...');
      _loadAppOpenAd();
      return;
    }
    if (_isShowingAppOpenAd) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      showAppOpenAd();
    }
  }

  // --- Interstitial Ad Logic ---

  void _loadInterstitialAd() {
    if (_isInterstitialAdLoading) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialTestId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd Loaded!');
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  void showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (_interstitialAd == null) {
      debugPrint('InterstitialAd not ready, calling callback directly.');
      onAdDismissed();
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed();
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  // --- Rewarded Ad Logic ---

  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedTestId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('RewardedAd Loaded!');
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  void showRewardedAd({required Function onRewardEarned}) {
    if (_rewardedAd == null) {
      debugPrint('RewardedAd not ready, trying to load...');
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd Dismissed');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd Failed to Show: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User Earned Reward!');
        onRewardEarned();
      },
    );
  }
}
