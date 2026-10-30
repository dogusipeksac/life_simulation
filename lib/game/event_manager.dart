// Olayları tutar ve oyun durumuna göre bir sonrakini seçer. Kendi içinde oyun durumu tutmaz.
// (Godot: Systems/EventManager.cs — ağırlıklar ve kurallar birebir)

import '../content/models.dart';
import 'conditions.dart';
import 'events.dart';
import 'rng.dart';
import 'state.dart';
import 'voice.dart';

class EventManager {
  /// Çeşitlilik için bakılan son olay sayısı.
  static const diversityWindow = 5;

  /// Pencerede aynı kategoriden k olay varsa ağırlık 1 / (1 + ceza·k) ile çarpılır.
  static const diversityPenalty = 0.75;

  /// Tekrarlanabilir bir olay bir hayatta en fazla bu kadar sunulur (Godot'da sınır yoktu).
  static const repeatCapPerLife = 3;

  final Map<String, EventDef> _events = {};
  // Aynı seed ile aynı seçim için ID'ye göre sabit sıra (ordinal).
  final List<EventDef> _sorted = [];
  final List<String> warnings = [];

  Map<String, EventDef> get events => _events;

  void register(Iterable<EventDef> events) {
    for (final ev in events) {
      if (ev.id.trim().isEmpty) continue;
      if (_events.containsKey(ev.id)) {
        warnings.add("Çift EventId '${ev.id}'. İkincisi yok sayıldı.");
        continue;
      }
      _events[ev.id] = ev;
    }
    _sorted
      ..clear()
      ..addAll(_events.values)
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  EventDef? getById(String? id) => id == null ? null : _events[id];

  EventDef? getNextEvent(GameState s, GameRandom rng) {
    if ((s.pendingEventId ?? '').isNotEmpty) {
      final pending = getById(s.pendingEventId);
      if (pending != null && hasAnyAvailableChoice(s, pending)) return pending;
      warnings.add("Zincir olayı '${s.pendingEventId}' gösterilemiyor; rastgele havuza geçiliyor.");
    }
    final candidates = <EventDef>[];
    final weights = <double>[];
    var total = 0.0;
    for (final ev in _sorted) {
      if (!isEligible(s, ev)) continue;
      final focus = (s.lifeFocus == 'Öğrenme' && (ev.category == EventCategory.school || ev.category == EventCategory.career)) ||
              (s.lifeFocus == 'İlişkiler' && ev.category == EventCategory.social) ||
              (s.lifeFocus == 'Sağlık' && ev.category == EventCategory.health)
          ? 1.6
          : 1.0;
      final unseen = ev.varietyFamily.isEmpty && !s.completedEventIds.contains(ev.id) ? 2.4 : 1.0;
      final debt = ev.id == 'random_debt_counselor' && s.flags.contains('bankrupt') ? 8.0 : 1.0;
      final weight = ev.weight * _diversityFactor(s, ev.category) * focus * categoryWeight(s, ev.category) * unseen * debt;
      if (weight <= 0) continue;
      candidates.add(ev);
      weights.add(weight);
      total += weight;
    }
    if (candidates.isEmpty) return null;

    // Katalog büyüklüğü yazılı hikâye zincirlerini boğmasın: iki havuz da uygunsa
    // çekilişlerin %65'i yazılı hikâyelere ayrılır.
    var authored = 0.0, generated = 0.0;
    for (var i = 0; i < candidates.length; i++) {
      if (candidates[i].varietyFamily.isEmpty) {
        authored += weights[i];
      } else {
        generated += weights[i];
      }
    }
    if (authored > 0 && generated > 0) {
      total = 0;
      for (var i = 0; i < candidates.length; i++) {
        weights[i] *= candidates[i].varietyFamily.isEmpty ? .65 / authored : .35 / generated;
        total += weights[i];
      }
    }
    var roll = rng.nextDouble() * total;
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll < 0) return candidates[i];
    }
    return candidates.last;
  }

  bool isEligible(GameState s, EventDef ev) {
    if (ev.chainOnly) return false;
    if (ev.id == 'social_proposal' && s.simulation.wedding.pending) return false;
    if (ev.id == 'social_new_baby' && s.flags.contains('childfree_choice')) return false;
    if (ev.varietyFamily.isNotEmpty && s.recentEventIds.any((r) => r.startsWith(ev.varietyFamily))) return false;
    if (s.age < ev.minAge || s.age > ev.maxAge) return false;
    if (s.educationLevel.index < ev.requiredEducation.index) return false;
    if (!allMet(s, ev.conditions)) return false;
    final lastSeen = s.eventLastSeenDay[ev.id];
    if (!ev.repeatable && (lastSeen != null || s.completedEventIds.contains(ev.id))) return false;
    if (lastSeen != null && s.day - lastSeen < ev.cooldownDays) return false;
    if ((s.eventShowCounts[ev.id] ?? 0) >= repeatCapPerLife) return false;
    return hasAnyAvailableChoice(s, ev);
  }

  static bool isChoiceAvailable(GameState s, ChoiceDef c) =>
      (c.cost <= 0 || s.money >= c.cost) && allMet(s, c.requirements);

  static bool hasAnyAvailableChoice(GameState s, EventDef ev) => ev.choices.any((c) => isChoiceAvailable(s, c));

  double _diversityFactor(GameState s, EventCategory category) {
    var same = 0;
    final start = s.recentEventIds.length - diversityWindow < 0 ? 0 : s.recentEventIds.length - diversityWindow;
    for (var i = start; i < s.recentEventIds.length; i++) {
      if (getById(s.recentEventIds[i])?.category == category) same++;
    }
    return 1 / (1 + diversityPenalty * same);
  }
}
