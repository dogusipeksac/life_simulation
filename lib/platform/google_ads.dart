import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../game/monetization.dart';

class GoogleAds implements AdGateway {
  static const testMode = bool.fromEnvironment(
    'AD_TEST_MODE',
    defaultValue: true,
  );

  /// Canlı birimler; isteğe bağlı `--dart-define` ile override.
  static const _prodRewardedAndroid =
      'ca-app-pub-1381327816086955/4928741009';
  static const _prodInterstitialAndroid =
      'ca-app-pub-1381327816086955/9219339803';
  static const _prodRewardedIos =
      'ca-app-pub-1381327816086955/2446047897';
  static const _prodInterstitialIos =
      'ca-app-pub-1381327816086955/2299155343';

  String get _rewardedId {
    if (testMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    const override = String.fromEnvironment('AD_REWARDED_UNIT');
    if (override.isNotEmpty) return override;
    return Platform.isAndroid ? _prodRewardedAndroid : _prodRewardedIos;
  }

  String get _interstitialId {
    if (testMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    const override = String.fromEnvironment('AD_INTERSTITIAL_UNIT');
    if (override.isNotEmpty) return override;
    return Platform.isAndroid
        ? _prodInterstitialAndroid
        : _prodInterstitialIos;
  }
  int _generation = 0;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  DateTime? _rewardedAt, _interstitialAt;
  bool _showing = false,
      _initializing = false,
      _disposed = false,
      _loadingReward = false,
      _loadingInterstitial = false,
      _allowed = false;
  @override
  bool privacyOptionsRequired = false;
  @override
  String status = 'Reklamlar hazırlanıyor…';
  @override
  void Function()? onChanged;
  void _changed() {
    if (!_disposed) onChanged?.call();
  }

  bool _fresh(DateTime? time) =>
      time != null &&
      DateTime.now().difference(time) < const Duration(hours: 1);
  @override
  bool get rewardedAvailable =>
      !_disposed &&
      _allowed &&
      !_showing &&
      _rewarded != null &&
      _fresh(_rewardedAt);
  @override
  bool get interstitialAvailable =>
      !_disposed &&
      _allowed &&
      !_showing &&
      _interstitial != null &&
      _fresh(_interstitialAt);
  @override
  Future<void> initialize() async {
    if (_initializing || _disposed) return;
    if (!Platform.isAndroid && !Platform.isIOS) {
      status = 'Reklamlar bu platformda kullanılamıyor.';
      _changed();
      return;
    }
    if (_rewardedId.isEmpty || _interstitialId.isEmpty) {
      status = 'Reklam birimleri bu sürümde yapılandırılmadı.';
      _changed();
      return;
    }
    _initializing = true;
    try {
      final updated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!updated.isCompleted) updated.complete();
        },
        (_) {
          if (!updated.isCompleted) updated.complete();
        },
      );
      await updated.future.timeout(const Duration(seconds: 15));
      if (_disposed) return;
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {})
          .timeout(const Duration(seconds: 15));
      _allowed = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!_allowed) {
        status = 'Reklam gizlilik durumu hazır değil. Oyuna reklamsız devam edebilirsin.';
        _changed();
        return;
      }
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.t),
      );
      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 15),
      );
      if (_disposed) return;
      _loadRewarded();
      _loadInterstitial();
    } catch (_) {
      status = 'Reklam ağına bağlanılamadı. Oyuna devam edebilirsin.';
    } finally {
      _initializing = false;
      _changed();
    }
  }

  void _loadRewarded() {
    if (_disposed || !_allowed || _loadingReward) return;
    final generation = _generation;
    _loadingReward = true;
    _rewarded?.dispose();
    _rewarded = null;
    unawaited(
      RewardedAd.load(
        adUnitId: _rewardedId,
        request: const AdRequest(nonPersonalizedAds: true),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (generation != _generation) {
              ad.dispose();
              return;
            }
            _loadingReward = false;
            if (_disposed || !_allowed) {
              ad.dispose();
              return;
            }
            _rewarded = ad;
            _rewardedAt = DateTime.now();
            status = testMode
                ? 'Resmi test reklamı hazır. Canlı reklam gösterilmez.'
                : 'İsteğe bağlı reklam hazır.';
            _changed();
          },
          onAdFailedToLoad: (_) {
            if (generation != _generation) return;
            _loadingReward = false;
            status = 'Reklam şu anda yüklenemedi. Ödül verilmedi; oyuna devam edebilirsin.';
            _changed();
          },
        ),
      ).catchError((Object _) {
        if (generation != _generation) return;
        _loadingReward = false;
        status = 'Reklam yüklenemedi.';
        _changed();
      }),
    );
  }

  void _loadInterstitial() {
    if (_disposed || !_allowed || _loadingInterstitial) return;
    final generation = _generation;
    _loadingInterstitial = true;
    _interstitial?.dispose();
    _interstitial = null;
    unawaited(
      InterstitialAd.load(
        adUnitId: _interstitialId,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (generation != _generation) {
              ad.dispose();
              return;
            }
            _loadingInterstitial = false;
            if (_disposed || !_allowed) {
              ad.dispose();
              return;
            }
            _interstitial = ad;
            _interstitialAt = DateTime.now();
            _changed();
          },
          onAdFailedToLoad: (_) {
            if (generation != _generation) return;
            _loadingInterstitial = false;
            _changed();
          },
        ),
      ).catchError((Object _) {
        if (generation != _generation) return;
        _loadingInterstitial = false;
      }),
    );
  }

  @override
  Future<bool> showRewarded() async {
    if (!rewardedAvailable) {
      if (!_showing) _loadRewarded();
      return false;
    }
    final ad = _rewarded!;
    _rewarded = null;
    _showing = true;
    _changed();
    final done = Completer<bool>();
    var earned = false;
    void finish(bool reward) {
      ad.dispose();
      _showing = false;
      if (!done.isCompleted) done.complete(reward);
      if (!_disposed) {
        _loadRewarded();
        _changed();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(earned),
      onAdFailedToShowFullScreenContent: (_, _) => finish(false),
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
    } catch (_) {
      finish(false);
    }
    return done.future;
  }

  @override
  Future<bool> showInterstitial() async {
    if (!interstitialAvailable) {
      if (!_showing) _loadInterstitial();
      return false;
    }
    final ad = _interstitial!;
    _interstitial = null;
    _showing = true;
    _changed();
    final done = Completer<bool>();
    var shown = false;
    void finish() {
      ad.dispose();
      _showing = false;
      if (!done.isCompleted) done.complete(shown);
      if (!_disposed) {
        _loadInterstitial();
        _changed();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        shown = true;
      },
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show();
    } catch (_) {
      finish();
    }
    return done.future;
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (_showing || _disposed) return;
    _allowed = false;
    _generation++;
    _loadingReward = false;
    _loadingInterstitial = false;
    _rewarded?.dispose();
    _rewarded = null;
    _interstitial?.dispose();
    _interstitial = null;
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {
      status = 'Gizlilik seçenekleri açılamadı. Yeniden deneyebilirsin.';
    }
    await initialize();
  }

  @override
  void dispose() {
    _disposed = true;
    _rewarded?.dispose();
    _interstitial?.dispose();
    _rewarded = null;
    _interstitial = null;
    onChanged = null;
  }
}
