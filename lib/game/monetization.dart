// Godot MonetizationService: 10 dk sessizlik, 3 dk ara ve 20 karar aralığı.
import 'state.dart';

abstract interface class AdGateway {
  bool get rewardedAvailable;
  bool get interstitialAvailable;
  String get status;
  bool get privacyOptionsRequired;
  void Function()? get onChanged;
  set onChanged(void Function()? value);
  Future<void> initialize();
  Future<bool> showRewarded();
  Future<bool> showInterstitial();
  Future<void> showPrivacyOptions();
  void dispose();
}

class NoAds implements AdGateway {
  @override
  bool get rewardedAvailable => false;
  @override
  bool get interstitialAvailable => false;
  @override
  String get status =>
      'Reklam şu anda kullanılamıyor. Oyuna devam edebilirsin.';
  @override
  bool get privacyOptionsRequired => false;
  @override
  void Function()? onChanged;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> showRewarded() async => false;
  @override
  Future<bool> showInterstitial() async => false;
  @override
  Future<void> showPrivacyOptions() async {}
  @override
  void dispose() {}
}

class InterstitialPolicy {
  InterstitialPolicy({Duration Function()? elapsed})
    : _elapsed = elapsed ?? (Stopwatch()..start()).elapsedTime;
  final Duration Function() _elapsed;
  Duration? _lastShown;
  int _lastChoice = -20;
  GameState? _lastLife;
  bool due(GameState? s, {required bool adsRemoved, required bool ready}) {
    if (s == null ||
        s.isGameOver ||
        adsRemoved ||
        !ready ||
        _elapsed() < const Duration(minutes: 10)) {
      return false;
    }
    if (_lastShown != null &&
        _elapsed() - _lastShown! < const Duration(minutes: 3)) {
      return false;
    }
    final previous = identical(s, _lastLife) ? _lastChoice : -20;
    return s.totalChoices >= 20 && s.totalChoices - previous >= 20;
  }

  void record(GameState s) {
    _lastShown = _elapsed();
    _lastChoice = s.totalChoices;
    _lastLife = s;
  }
}

extension on Stopwatch {
  Duration elapsedTime() => elapsed;
}
