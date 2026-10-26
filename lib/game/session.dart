// Oyun akışının tek kapısı: olay sunma, seçim işleme, tur ilerletme. (Godot: Core/GameManager.cs)
//
// Kariyer, okul, ekonomi, ülke ve ilişki kuralları aynı zaman hattından geçer.

import '../content/game_content.dart';
import '../content/models.dart';
import 'catalog.dart';
import 'conditions.dart';
import 'director.dart';
import 'effects.dart';
import 'event_manager.dart';
import 'events.dart';
import 'family.dart';
import 'rng.dart';
import 'progression.dart';
import 'social.dart';
import 'wedding.dart';
import 'world.dart';
import 'save.dart';
import 'state.dart';
import 'text.dart';
import 'voice.dart';

/// Godot: Data/Config/TimeConfig.tres
abstract final class TimeConfig {
  static const daysPerYear = 365, monthsPerYear = 12;
  static const startAge = 0, maxLifeAge = 100, fallbackTurnDays = 30;

  /// (yaş üst sınırı, en az gün, en çok gün)
  static const turnLengths = [
    (2, 30, 60),
    (6, 45, 75),
    (13, 45, 75),
    (18, 30, 45),
    (65, 180, 365),
    (101, 180, 365),
  ];

  static int absoluteMonth(int totalDay) =>
      totalDay * monthsPerYear ~/ daysPerYear;
}

/// Godot: Data/Config/EconomyConfig.tres DebtLimit.
const debtLimit = 150000;

class ActionResult {
  const ActionResult(this.success, this.message);
  final bool success;
  final String message;
}

class GameSession {
  GameSession(this.content, this.saves)
    : director = NarrativeDirector(content.scenes) {
    events
      ..register(content.events.values.map(EventDef.fromContent))
      ..register(buildLifeCatalog())
      ..register(director.prototypes());
  }

  static const maxPlayerNameLength = 20;

  final GameContent content;
  final SaveService saves;
  final EventManager events = EventManager();
  final NarrativeDirector director;
  final EffectProcessor effects = EffectProcessor(moneyFloor: -debtLimit);

  late final Progression progression = Progression(content, effects);

  bool autoSaveEnabled = true;

  GameState? state;
  EventDef? currentEvent;
  GameRandom? _rng;
  TurnReport? _turnReport;

  static String? validatePlayerName(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'Bir isim yazmalısın.';
    if (t.length > maxPlayerNameLength) {
      return 'İsim en fazla $maxPlayerNameLength karakter olabilir.';
    }
    return null;
  }

  Family? familyOf(GameState s) =>
      content.families.where((f) => f.id == s.profile.familyId).firstOrNull;

  void startNewGame(
    String playerName, {
    required int seed,
    CharacterProfile? profile,
  }) {
    final s = GameState.createNew(playerName.trim(), TimeConfig.startAge, seed);
    if (profile != null) s.profile = profile..ensureValid();
    final family = familyOf(s) ?? rollFamily(content.families, seed);
    applyBirth(s, family);
    applyBirthTraits(s);
    ensureFamily(s);
    s.simulation
      ..initialized = true
      ..lastWorldAge = s.age;
    final origin = family == null ? '' : ' ${family.name}.';
    s.journal.add(
      JournalEntry(
        age: s.age,
        title: 'Dünyaya merhaba',
        memory:
            '${s.profile.birthdayText} günü ${s.profile.birthplace} şehrinde bir hayat başladı.$origin ${s.profile.caregiver} yanında.',
      ),
    );
    s.pendingEventId = s.age == 0 ? 'baby_welcome' : null;
    state = s;
    _rng = GameRandom(s);
    currentEvent = null;
    progression.enroll(s, null);
    progression.assignGoals(s, _rng!);
    _autoSave();
  }

  LoadResult continueGame() {
    final result = saves.load();
    if (result.status == LoadStatus.loaded && result.state != null) {
      final s = state = result.state!;
      ensureFamily(s);
      if (!s.simulation.initialized) {
        s.simulation
          ..initialized = true
          ..lastWorldAge = s.age
          ..lastCareerId = s.careerId ?? '';
      }
      _rng = GameRandom(s);
      Wedding.reconcile(s);
      progression.enroll(s, null);
      progression.assignGoals(s, _rng!);
      currentEvent = null;
      // Yedekten yüklendi: sağlam hali hemen asıl dosyaya yaz.
      if (result.loadedFrom != saves.savePath) _autoSave();
    }
    return result;
  }

  /// Ekrandaki olayın kişiselleştirilmiş metni.
  String describeCurrent() {
    final s = state, ev = currentEvent;
    if (s == null || ev == null) return '';
    return describeEvent(s, ev, family: familyOf(s));
  }

  List<ChoiceView> choiceViews(EventDef ev) {
    final s = state;
    if (s == null) return const [];
    return [
      for (final c in ev.choices)
        ChoiceView(
          c.id,
          fillVoice(s, c.text),
          c.cost,
          EventManager.isChoiceAvailable(s, c),
          [
            if (c.cost > 0 && s.money < c.cost)
              '${formatMoney(c.cost)} nakit gerekli',
            ...describeUnmet(s, c.requirements, content.flags),
          ],
          _describeChoice(c),
        ),
    ];
  }

  /// Sıradaki olayı hazırlar. Uygun olay yoksa sakin bir tur geçer ve [GameState.pendingMoment] dolar.
  EventDef? requestNextEvent() {
    final s = state, rng = _rng;
    if (s == null || rng == null || s.isGameOver) return null;
    s.pendingMoment = null;
    // Uygulama bir olay ekrandayken kapandıysa aynı olaydan devam.
    if (currentEvent == null && (s.currentEventId ?? '').isNotEmpty) {
      _updateNarrativeContext();
      final id = s.currentEventId!;
      currentEvent = id == World.electionId
          ? World.election(s)
          : id == Wedding.eventId
          ? Wedding.prepare(s)
          : director.isDirected(id)
          ? director.restore(s, id)
          : events.getById(id);
      if (currentEvent == null) s.currentEventId = null;
    }
    if (currentEvent == null) {
      _updateNarrativeContext();
      currentEvent = (s.pendingEventId ?? '').isNotEmpty
          ? events.getNextEvent(s, rng)
          : World.election(s) ??
                Wedding.prepare(s) ??
                director.next(s, rng) ??
                events.getNextEvent(s, rng);
      if (currentEvent == null) {
        _passCalmTurn();
        return null;
      }
      s.pendingEventId = null;
      s.currentEventId = currentEvent!.id;
      _autoSave();
    }
    return currentEvent;
  }

  ChoiceResult? submitChoice(String choiceId) {
    final s = state, rng = _rng, ev = currentEvent;
    if (s == null || rng == null || ev == null) return null;
    final choice = ev.findChoice(choiceId);
    if (choice == null || !EventManager.isChoiceAvailable(s, choice)) {
      return null;
    }

    final result = effects.applyChoice(s, ev, choice);
    director.resolve(s, ev, choice, result);
    if (ev.id == World.electionId) World.vote(s, choice.id, result);
    if (ev.id == Wedding.eventId) {
      Wedding.resolve(s, choice.id, rng, effects, result);
    }
    if (ev.id == 'social_proposal' && choice.id == 'marry') {
      Wedding.reconcile(s);
      final partner = s.relationships
          .where((p) => p.alive && p.role == 'Partner')
          .firstOrNull;
      if (partner != null) result.resultText = Wedding.plan(s, partner).$2;
    }
    s.totalChoices++;
    s.journal.add(
      JournalEntry(
        age: s.age,
        day: s.day,
        title: ev.title,
        choice: fillVoice(s, choice.text),
        memory: result.resultText,
      ),
    );
    if (s.journal.length > 300) s.journal.removeAt(0);
    currentEvent = null;
    s.currentEventId = null;
    final days = ev.turnDays > 0 ? ev.turnDays : _defaultTurnDays(s, rng);
    result.turn = _advanceTime(days);
    _afterTurn(result.turn);
    s.pendingMoment = SavedMoment(
      title: ev.title,
      text: result.resultText,
      changes: [...result.changes],
      turn: result.turn,
    );
    _autoSave();
    return result;
  }

  /// "Yeni yaş": doğum gününe atlar; seçimlerle aynı aylık/yaşlanma hattından geçer.
  ActionResult advanceToBirthday() {
    final s = state;
    if (s == null || s.isGameOver) {
      return const ActionResult(false, 'Bu hayat sona erdi.');
    }
    if (currentEvent != null ||
        (s.currentEventId ?? '').isNotEmpty ||
        (s.pendingEventId ?? '').isNotEmpty) {
      return const ActionResult(
        false,
        'Önce hikâyendeki bekleyen kararı tamamla. Yeni yaşta seni yeni kararlar bekliyor.',
      );
    }
    final report = _advanceTime(TimeConfig.daysPerYear - s.dayOfYear);
    _afterTurn(report);
    _remember(s, '${s.age}. yaş', report.notes.join('\n'));
    s.pendingMoment = _calmMoment(s, report);
    _autoSave();
    return ActionResult(true, '${report.days} gün geçti. ${s.age} yaşındasın.');
  }

  /// Yaşanan hayatın sonu (oyun sonu ekranı). Tam özet P5'te.
  Ending? get ending =>
      content.endings.where((e) => e.id == state?.endingId).firstOrNull;

  ActionResult _commit((bool, String) result) {
    _afterTurn(null);
    _autoSave();
    return ActionResult(result.$1, result.$2);
  }

  ActionResult applyCareer(String id) => state == null || state!.isGameOver
      ? const ActionResult(false, 'Oyun devam etmiyor.')
      : _commit(progression.apply(state!, id, _rng!));
  ActionResult trustFate() => state == null || state!.isGameOver
      ? const ActionResult(false, 'Oyun devam etmiyor.')
      : _commit(progression.fate(state!, _rng!));
  void quitCareer() {
    if (state == null || state!.isGameOver) return;
    progression.quit(state!);
    _autoSave();
  }

  ActionResult doAction(String id, {String? personId}) {
    if (state == null) {
      return const ActionResult(false, 'Önce bir hayata başla.');
    }
    final result = Social.perform(state!, effects, id, personId);
    if (result.$1) return _commit(result);
    return ActionResult(false, result.$2);
  }

  ActionResult setFocus(String focus) {
    final s = state;
    if (s == null || s.isGameOver || !lifeFocuses.contains(focus)) {
      return const ActionResult(false, 'Öncelik değiştirilemedi.');
    }
    final wait = 90 - (s.day - s.focusChangedDay);
    if (wait > 0) {
      return ActionResult(false, '$wait gün sonra yeniden değiştirebilirsin.');
    }
    s.lifeFocus = focus;
    s.focusChangedDay = s.day;
    _autoSave();
    return ActionResult(true, 'Bu dönemde önceliğin: $focus.');
  }

  ActionResult transferBank(int amount, {required bool deposit}) {
    final s = state;
    if (s == null || s.isGameOver) {
      return const ActionResult(false, 'Oyun devam etmiyor.');
    }
    if (s.age < 18) {
      return const ActionResult(false, 'Banka hesabı 18 yaşında açılır.');
    }
    if (amount <= 0 || amount > 1000000000000) {
      return const ActionResult(false, 'Geçerli bir tutar gir.');
    }
    if (deposit &&
        (s.money < amount || s.bankBalance > 1000000000000 - amount)) {
      return const ActionResult(
        false,
        'Nakit yetersiz veya hesap limitine ulaştın.',
      );
    }
    if (!deposit &&
        (s.bankBalance < amount || s.money > 0x7FFFFFFFFFFFFFFF - amount)) {
      return const ActionResult(
        false,
        'Banka bakiyesi yetersiz veya nakit limitine ulaştın.',
      );
    }
    effects.applyStat(s, Stat.money, deposit ? -amount : amount);
    s.bankBalance += deposit ? amount : -amount;
    final message =
        '${formatMoney(amount)} ${deposit ? 'bankaya yatırıldı.' : 'bankadan çekildi.'}';
    remember(s, 'Banka işlemi', message);
    return _commit((true, message));
  }

  ActionResult sellGold(int units) {
    final s = state;
    if (s == null ||
        s.isGameOver ||
        units <= 0 ||
        units > s.simulation.goldWallet) {
      return const ActionResult(false, 'Geçerli bir oyun altını miktarı seç.');
    }
    s.simulation.goldWallet -= units;
    final amount = units * Wedding.goldValue(s);
    effects.applyStat(s, Stat.money, amount);
    final message =
        '$units oyun altını ${formatMoney(amount)} nakde çevrildi. Bu değer gerçek altın fiyatını temsil etmez.';
    remember(s, 'Takı cüzdanı', message);
    return _commit((true, message));
  }

  ActionResult startMiniGame(String game) {
    final s = state;
    if (s == null || s.isGameOver) {
      return const ActionResult(false, 'Oyun devam etmiyor.');
    }
    if (!['memory', 'balls'].contains(game)) {
      return const ActionResult(false, 'Oyun bulunamadı.');
    }
    final reason = Social.blocked(
      s,
      const LifeAction('minigame', '✿', 'Zihin oyunu', '', '', 3),
    );
    if (reason != null) return ActionResult(false, reason);
    Social.consume(s, 'activity:minigame');
    // Token oyun RNG'sini tüketmez; eski oturum aynı gün yeniden açılamaz.
    s.miniGameSession = '${s.rngSeed}:${s.day}:${s.age}:${s.actionsUsed}';
    _autoSave();
    return ActionResult(true, s.miniGameSession);
  }

  ActionResult finishMiniGame(String token, int score) {
    final s = state;
    if (s == null ||
        s.isGameOver ||
        token.isEmpty ||
        s.miniGameSession != token) {
      return const ActionResult(false, 'Bu oyun oturumu sona erdi.');
    }
    score = score.clamp(0, 5);
    s.miniGameSession = '';
    effects.applyStat(s, Stat.education, score);
    effects.applyStat(s, Stat.happiness, 2);
    if (score >= 3) s.miniGamesWon++;
    final message = '5 turda $score doğru! +$score zihin, +2 mutluluk.';
    remember(s, 'Zihin oyunu', message);
    return _commit((true, message));
  }

  // ------------------------------------------------------------------ İç akış

  void _passCalmTurn() {
    final s = state!;
    final report = _advanceTime(_defaultTurnDays(s, _rng!));
    _afterTurn(report);
    s.pendingMoment = _calmMoment(s, report);
    _autoSave();
  }

  SavedMoment _calmMoment(GameState s, TurnReport report) =>
      SavedMoment(title: 'Sakin Bir Dönem', text: calmPeriod(s), turn: report);

  int _defaultTurnDays(GameState s, GameRandom rng) {
    for (final (maxAge, minDays, maxDays) in TimeConfig.turnLengths) {
      if (s.age < maxAge) {
        final days = rng.rangeInt(
          minDays,
          maxDays < minDays ? minDays : maxDays,
        );
        return s.profile.detailedLife
            ? (days ~/ 3 < 14 ? 14 : days ~/ 3)
            : days;
      }
    }
    return TimeConfig.fallbackTurnDays;
  }

  TurnReport _advanceTime(int days) {
    final s = state!;
    final report = TurnReport(days: days);
    _turnReport = report;
    progression.enroll(s, report);
    final start = s.day;
    // Uzun tur, sağlık tükenince veya son yaşa ulaşınca o gün biter.
    for (
      var i = 0;
      i < days && s.health > 0 && s.age < TimeConfig.maxLifeAge;
      i++
    ) {
      final monthBefore = TimeConfig.absoluteMonth(s.day);
      s.day++;
      s.dayOfYear++;
      final month = TimeConfig.absoluteMonth(s.day);
      if (month != monthBefore) _onMonthPassed(month);
      if (s.dayOfYear >= TimeConfig.daysPerYear) {
        s.dayOfYear = 0;
        s.age++;
        _onBirthday(s.age);
      }
    }
    report.days = s.day - start;
    _turnReport = null;
    return report;
  }

  void _onMonthPassed(int absoluteMonth) {
    progression.promote(state!, _rng!, _turnReport);
    World.month(state!, _rng!, _turnReport);
    progression.processMonth(state!, absoluteMonth, _turnReport);
  }

  void _onBirthday(int age) {
    final s = state!;
    _turnReport?.notes.add(
      '${s.profile.birthdayText}: Doğum günün kutlu olsun, artık $age yaşındasın!',
    );
    World.birthday(s, _rng!, _turnReport);
    Social.birthday(s);
    progression.schoolBirthday(s, _turnReport);
    progression.careerBirthday(s, _turnReport);
    _aging(s);
  }

  /// Yaşa bağlı sağlık kaybı. (Godot: Systems/AgingSystem.cs + content/life.json)
  void _aging(GameState s) {
    final c = content.life;
    if (s.age < c.declineStartAge) {
      if (c.recoveryPerYear > 0) {
        effects.applyStat(s, Stat.health, c.recoveryPerYear);
      }
      return;
    }
    final loss = yearlyHealthLoss(s, c);
    if (loss > 0) effects.applyStat(s, Stat.health, -loss);
  }

  static int yearlyHealthLoss(GameState s, LifeConfig c) {
    if (s.age < c.declineStartAge) return 0;
    var loss =
        c.baseYearlyLoss +
        (s.age - c.declineStartAge) ~/
            (c.extraLossEveryYears < 1 ? 1 : c.extraLossEveryYears);
    for (final m in c.flagModifiers.entries) {
      if (s.flags.contains(m.key)) loss += m.value;
    }
    if (s.happiness < c.lowHappinessThreshold) loss += c.lowHappinessExtraLoss;
    return loss < 0 ? 0 : loss;
  }

  void _afterTurn(TurnReport? report) {
    final s = state!;
    Wedding.reconcile(s);
    progression.checkGoals(s, report);
    // Başarımlar P5 aşamasında bağlanacak.
    if (!s.isGameOver) {
      if (s.health <= 0) {
        s.isGameOver = true;
        s.gameOverReason = GameOverReason.healthDepleted;
      } else if (s.age >= TimeConfig.maxLifeAge) {
        s.isGameOver = true;
        s.gameOverReason = GameOverReason.oldAge;
      }
    }
    if (s.isGameOver) s.endingId = _pickEnding(s)?.id;
  }

  /// Koşulları sağlanan en yüksek öncelikli son; eşitlikte ID sırası. (Godot: EndingSystem.cs)
  Ending? _pickEnding(GameState s) {
    final sorted = [...content.endings]
      ..sort(
        (a, b) => a.priority != b.priority
            ? b.priority.compareTo(a.priority)
            : a.id.compareTo(b.id),
      );
    return sorted.where((e) => allMet(s, e.conditions)).firstOrNull;
  }

  void _updateNarrativeContext() {
    final s = state!;
    s.simulation.occupation = describeOccupation();
    s.simulation.careerTheme = content.careers[s.careerId]?.theme ?? '';
  }

  /// Künyedeki kısa meslek / öğrenim durumu.
  String describeOccupation() {
    final s = state;
    if (s == null) return '';
    if (s.age < 6) {
      return s.age < 2 ? 'Dünyayı tanımaya başlıyor' : 'Oyunlarla büyüyor';
    }
    final career = content.careers[s.careerId];
    if (career != null && career.levels.isNotEmpty) {
      return career.levels[(s.careerLevel - 1).clamp(
        0,
        career.levels.length - 1,
      )];
    }
    if (s.studyLevel != null) {
      return '${educationDisplay(s.studyLevel!)} öğrencisi';
    }
    if (s.flags.contains('retired')) return 'Emekli';
    return s.age >= 18 ? 'İşsiz' : 'Okul dışında';
  }

  static void _remember(GameState s, String title, String memory) {
    s.journal.add(
      JournalEntry(age: s.age, day: s.day, title: title, memory: memory),
    );
    if (s.journal.length > 300) s.journal.removeAt(0);
  }

  static String _describeChoice(ChoiceDef c) {
    var up = 0, down = 0;
    for (final e in c.effects) {
      if (e.amount == 0 || e.stat == Stat.money) continue;
      e.amount > 0 ? up++ : down++;
    }
    if (c.cost > 0) return 'Bir bedeli var';
    if (up > 0 && down > 0) return 'Bir şey artar, bir şey eksilir';
    if (up > 0) return 'Sana iyi gelir';
    if (down > 0) return 'Zor bir karar';
    return '';
  }

  void save() => _autoSave();

  void _autoSave() {
    if (autoSaveEnabled && state != null) saves.save(state!);
  }
}
