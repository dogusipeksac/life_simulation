// İstatistik değişikliklerinin TEK kapısı. Olay verisi state'e doğrudan dokunmaz;
// her etki buradan, sınırlar korunarak geçer. (Godot: Systems/EffectProcessor.cs)

import '../content/models.dart';
import 'events.dart';
import 'state.dart';
import 'voice.dart';

class ChoiceResult {
  ChoiceResult({required this.eventId, required this.choiceId, required this.resultText, this.nextEventId});

  final String eventId, choiceId;
  String resultText;
  final String? nextEventId;
  final List<StatChange> changes = [];
  final List<String> flagsSet = [], flagsRemoved = [];
  TurnReport turn = TurnReport();
}

const _maxInt = 0x7FFFFFFFFFFFFFFF;
const _minInt = -0x8000000000000000;

class EffectProcessor {
  EffectProcessor({this.moneyFloor = 0});

  static const recentEventHistoryLength = 10;

  /// Paranın inebileceği en düşük değer; null = sınırsız.
  final int? moneyFloor;

  ChoiceResult applyChoice(GameState s, EventDef ev, ChoiceDef choice) {
    final result = ChoiceResult(
      eventId: ev.id,
      choiceId: choice.id,
      resultText: fillVoice(s, choice.result),
      nextEventId: choice.nextEventId.isEmpty ? null : choice.nextEventId,
    );
    if (choice.cost > 0) result.changes.add(applyStat(s, Stat.money, -choice.cost));
    for (final effect in choice.effects) {
      var amount = effect.amount;
      // Süresi sabit hikâye anları iki tempoda da aynıdır. Diğer stat etkileri üçte bir
      // birikir ki daha çok tur kazançları üçe katlamasın.
      if (s.profile.detailedLife && ev.turnDays == 0 && effect.stat != Stat.money) {
        final scaled = amount + (s.effectRemainders[effect.stat] ?? 0);
        amount = scaled ~/ 3; // C# tam sayı bölmesi sıfıra doğru keser; ~/ de öyle.
        s.effectRemainders[effect.stat] = scaled.remainder(3);
      }
      result.changes.add(applyStat(s, effect.stat, amount));
    }
    for (final f in choice.removeFlags) {
      if (s.flags.remove(f)) result.flagsRemoved.add(f);
    }
    for (final f in choice.setFlags) {
      if (s.flags.add(f)) result.flagsSet.add(f);
    }
    s.pendingEventId = result.nextEventId;
    _recordEvent(s, ev);
    return result;
  }

  StatChange applyStat(GameState s, Stat stat, int amount) {
    if (stat == Stat.money) {
      final before = s.money;
      var after = _saturatingAdd(before, amount);
      if (moneyFloor != null && after < moneyFloor!) after = moneyFloor!;
      s.money = after;
      return StatChange(stat, amount, after - before, after);
    }
    final current = s.getStat(stat);
    final next = (current + amount).clamp(GameState.statMin, GameState.statMax);
    switch (stat) {
      case Stat.health:
        s.health = next;
      case Stat.happiness:
        s.happiness = next;
      case Stat.education:
        s.education = next;
      case Stat.social:
        s.social = next;
      case Stat.money:
    }
    return StatChange(stat, amount, next - current, next);
  }

  static void _recordEvent(GameState s, EventDef ev) {
    if (!s.completedEventIds.contains(ev.id)) s.completedEventIds.add(ev.id);
    s.eventLastSeenDay[ev.id] = s.day;
    s.eventShowCounts[ev.id] = (s.eventShowCounts[ev.id] ?? 0) + 1;
    s.recentEventIds.add(ev.id);
    if (s.recentEventIds.length > recentEventHistoryLength) s.recentEventIds.removeAt(0);
  }

  static int _saturatingAdd(int a, int b) {
    final sum = a + b;
    if (((a ^ sum) & (b ^ sum)) < 0) return a > 0 ? _maxInt : _minInt;
    return sum;
  }
}
