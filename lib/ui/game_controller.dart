import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import '../game/events.dart';
import '../game/billing.dart';
import '../game/monetization.dart';
import '../game/atomic_file.dart';
import '../game/story_library.dart';
import '../game/story_store.dart';
import '../game/family.dart';
import '../game/save.dart';
import '../game/session.dart';
import '../game/state.dart';

/// Widget'ların tek kapısı: okur ve niyet gönderir, hesap yapmaz.
class GameController extends ChangeNotifier {
  GameController(
    this.session, {
    BillingGateway? billing,
    AdGateway? ads,
    InterstitialPolicy? interstitialPolicy,
  }) : ads = ads ?? NoAds(),
       interstitialPolicy = interstitialPolicy ?? InterstitialPolicy() {
    final directory = File(session.saves.savePath).parent.path;
    storyStore = StoryStore(
      session.content.stories.values.map((b) => b.productId),
      AtomicTextFile('$directory/story-entitlements.json'),
      gateway: billing,
    )..load();
    stories = StoryLibrary(
      session.content.stories,
      AtomicTextFile('$directory/story-progress.json'),
      ownsProduct: storyStore.owns,
    )..load();
    storyStore.onChanged = _platformChanged;
    this.ads.onChanged = _platformChanged;
  }
  late final StoryLibrary stories;
  late final StoryStore storyStore;
  void openBook(String id) {
    stories.open(id);
    notifyListeners();
  }

  ActionResult chooseStory(String id, int index, String expectedNode) =>
      _update(stories.choose(id, index, expectedNode: expectedNode));
  ActionResult resolveStoryInteraction(String id, String outcome, String expectedNode, {Set<String> found = const {}}) =>
      _update(stories.resolveInteraction(id, outcome, expectedNode: expectedNode, found: found));
  ActionResult restartStory(String id) => _update(stories.restart(id));
  ActionResult restoreStories() => _update(storyStore.restore());
  ActionResult purchaseStory(String product) =>
      _update(storyStore.purchase(product));

  final AdGateway ads;
  final InterstitialPolicy interstitialPolicy;
  bool rewardBusy = false, transitionBusy = false, _disposed = false;
  GameState? _pendingRewardState;
  bool? _pendingRewardIsSecondChance;
  String monetizationNotice = '';
  bool get retryBreathAvailable =>
      identical(state, _pendingRewardState) &&
      _pendingRewardIsSecondChance == false;
  bool get retrySecondChanceAvailable =>
      identical(state, _pendingRewardState) &&
      _pendingRewardIsSecondChance == true;
  void _clearPendingReward() {
    _pendingRewardState = null;
    _pendingRewardIsSecondChance = null;
  }

  void _platformChanged() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initializePlatformServices() async {
    await Future.wait([
      () async {
        await storyStore.initialize();
        if (!_disposed && (storyStore.gateway?.available ?? false)) {
          storyStore.restore();
        }
      }(),
      ads.initialize(),
    ]);
    _platformChanged();
  }

  void onResume() {
    if (storyStore.gateway?.available == true && !storyStore.busy) {
      storyStore.restore();
    }
  }

  Future<void> refreshAds() async {
    await ads.initialize();
    _platformChanged();
  }

  Future<void> showAdPrivacyOptions() async {
    await ads.showPrivacyOptions();
    _platformChanged();
  }

  Future<ActionResult> rewardedBreath() => _reward(false);
  Future<ActionResult> secondChance() => _reward(true);
  Future<ActionResult> _reward(bool secondChance) async {
    final expected = state;
    if (rewardBusy || transitionBusy || expected == null) {
      return const ActionResult(false, 'Devam eden işlemi bekle.');
    }
    if (secondChance
        ? !session.canSecondChance
        : expected.isGameOver || session.breathsRemaining == 0) {
      return const ActionResult(false, 'Bu hayatta bu ödül kullanılamaz.');
    }
    final retry = secondChance
        ? retrySecondChanceAvailable
        : retryBreathAvailable;
    if (!retry && !ads.rewardedAvailable) {
      return ActionResult(false, ads.status);
    }
    rewardBusy = true;
    _platformChanged();
    ActionResult result;
    try {
      final earned = retry || await ads.showRewarded();
      if (_disposed) return const ActionResult(false, 'Oturum sona erdi.');
      if (earned && identical(state, expected)) {
        _pendingRewardState = expected;
        _pendingRewardIsSecondChance = secondChance;
      }
      result = earned
          ? (secondChance
                ? session.grantSecondChance(expected)
                : session.grantBreath(expected))
          : const ActionResult(false, 'Reklam tamamlanmadı. Ödül verilmedi.');
      if (result.success || !identical(state, expected)) _clearPendingReward();
      if (result.success && secondChance) session.requestNextEvent();
    } catch (_) {
      result = const ActionResult(
        false,
        'Reklam gösterilemedi. Ödül verilmedi.',
      );
    } finally {
      rewardBusy = false;
      _platformChanged();
    }
    monetizationNotice = result.message;
    _platformChanged();
    return result;
  }

  Future<void> continueAfterAd() async {
    if (transitionBusy || rewardBusy || state == null || state!.isGameOver) {
      return;
    }
    final expected = state!;
    transitionBusy = true;
    _platformChanged();
    try {
      if (interstitialPolicy.due(
        expected,
        adsRemoved: storyStore.adsRemoved,
        ready: ads.interstitialAvailable,
      )) {
        if (await ads.showInterstitial()) interstitialPolicy.record(expected);
      }
    } catch (_) {
      /* Reklam hatası hikâyeyi durdurmaz. */
    }
    // Aynı karede gelen ikinci dokunma, reklam gösterilmese de kararı atlamasın.
    await Future<void>.value();
    if (!_disposed && identical(state, expected)) continueStory();
    transitionBusy = false;
    _platformChanged();
  }

  @override
  void dispose() {
    _disposed = true;
    storyStore.dispose();
    ads.dispose();
    super.dispose();
  }

  final GameSession session;

  /// Açılış ekranında gösterilecek kayıt sorunu (ör. bozuk kayıt).
  String? notice;

  GameState? get state => session.state;
  EventDef? get event => session.currentEvent;
  SavedMoment? get moment => state?.pendingMoment;
  bool get hasSave => session.saves.hasSave();
  bool get inGame => state != null;

  static int newSeed() {
    final r = Random.secure();
    return (r.nextInt(1 << 32) << 32) | r.nextInt(1 << 32);
  }

  Family? previewFamily(int seed) => rollFamily(session.content.families, seed);

  void startNewGame(
    String name, {
    required int seed,
    CharacterProfile? profile,
  }) {
    _clearPendingReward();
    session.startNewGame(name, seed: seed, profile: profile);
    notice = null;
    if (state!.pendingMoment == null) session.requestNextEvent();
    notifyListeners();
  }

  /// Kayıtlı hayata devam. Başarısızsa [notice] dolar ve false döner.
  bool continueGame() {
    final r = session.continueGame();
    switch (r.status) {
      case LoadStatus.loaded:
        if (!state!.isGameOver && state!.pendingMoment == null) {
          session.requestNextEvent();
        }
        notice = null;
        notifyListeners();
        return true;
      case LoadStatus.unsupportedVersion:
        notice = unsupportedSaveMessage;
      case LoadStatus.corrupted:
        notice = corruptedSaveMessage;
      case LoadStatus.noSave:
        notice = null;
    }
    notifyListeners();
    return false;
  }

  List<ChoiceView> get choices =>
      event == null ? const [] : session.choiceViews(event!);

  String get eventText => session.describeCurrent();

  void choose(String id) {
    if (session.submitChoice(id) != null) notifyListeners();
  }

  /// Kütüphane sekmesinde açık kitap (görünüm durumu): geri tuşu önce kitabı kapatır.
  String? libraryBook;

  /// Ekrandaki olayın oynanmamış anı.
  LifeMoment? get lifeMoment => session.activeMoment();

  /// Oynanmış anın sahneye eklediği cümle ve değişimler (karar verilene kadar).
  String get momentNote => state?.momentNote ?? '';
  List<StatChange> get momentChanges => state?.momentChanges ?? const [];

  ActionResult resolveMoment(String outcome, {Set<int> indices = const {}}) =>
      _update(session.resolveMoment(outcome, found: indices));

  /// Süreli kararda süre doldu.
  void momentTimeout() {
    if (session.momentTimeout() != null) notifyListeners();
  }

  /// Sonuç sayfasından "Hikâyeye devam et".
  void continueStory() {
    session.requestNextEvent();
    notifyListeners();
  }

  /// Oyun bittiğinde son sonuç okununca final sayfasına geçilir.
  void acknowledgeMoment() {
    state?.pendingMoment = null;
    session.save();
    notifyListeners();
  }

  ActionResult newAge() {
    final r = session.advanceToBirthday();
    notifyListeners();
    return r;
  }

  ActionResult _update(ActionResult result) {
    notifyListeners();
    return result;
  }

  ActionResult applyCareer(String id) => _update(session.applyCareer(id));
  ActionResult trustFate() => _update(session.trustFate());
  void quitCareer() {
    session.quitCareer();
    notifyListeners();
  }

  ActionResult doAction(String id, {String? personId}) =>
      _update(session.doAction(id, personId: personId));
  ActionResult setFocus(String focus) => _update(session.setFocus(focus));
  ActionResult transferBank(int amount, {required bool deposit}) =>
      _update(session.transferBank(amount, deposit: deposit));
  ActionResult sellGold(int units) => _update(session.sellGold(units));
  ActionResult startMiniGame(String id) => _update(session.startMiniGame(id));
  ActionResult finishMiniGame(String token, int score) =>
      _update(session.finishMiniGame(token, score));

  void leaveToTitle() {
    _clearPendingReward();
    session.save();
    session.state = null;
    session.currentEvent = null;
    notifyListeners();
  }

  void save() => session.save();
}
