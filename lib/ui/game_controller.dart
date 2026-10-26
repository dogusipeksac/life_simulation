import 'dart:math';

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import '../game/events.dart';
import '../game/family.dart';
import '../game/save.dart';
import '../game/session.dart';
import '../game/state.dart';

/// Widget'ların tek kapısı: okur ve niyet gönderir, hesap yapmaz.
class GameController extends ChangeNotifier {
  GameController(this.session);

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
    session.save();
    session.state = null;
    session.currentEvent = null;
    notifyListeners();
  }

  void save() => session.save();
}
