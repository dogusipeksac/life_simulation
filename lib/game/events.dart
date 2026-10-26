// Oyun anında sunulan olay. İçerik olayları, üretilen katalog ve sahne yönetmeninin
// kurduğu sahneler aynı biçime çevrilir. (Godot: Data/EventResource.cs + ChoiceResource.cs)

import '../content/models.dart';

class StatEffect {
  const StatEffect(this.stat, this.amount);
  final Stat stat;
  final int amount;
}

class ChoiceDef {
  ChoiceDef({
    required this.id,
    required this.text,
    required this.result,
    this.effects = const [],
    this.cost = 0,
    this.requirements = const [],
    this.setFlags = const [],
    this.removeFlags = const [],
    this.nextEventId = '',
  });

  factory ChoiceDef.fromContent(EventChoice c) => ChoiceDef(
        id: c.id,
        text: c.text,
        result: c.result,
        effects: [
          for (final e in c.effects.entries)
            if (enumByName(Stat.values, e.key) case final s?) StatEffect(s, e.value),
        ],
        cost: c.cost,
        requirements: c.requires,
        setFlags: c.set,
        removeFlags: c.remove,
        nextEventId: c.next,
      );

  final String id, text, result, nextEventId;
  final List<StatEffect> effects;
  final int cost;
  final List<Condition> requirements;
  final List<String> setFlags, removeFlags;
}

class EventDef {
  EventDef({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.minAge = 0,
    this.maxAge = 100,
    this.requiredEducation = Education.none,
    this.conditions = const [],
    required this.choices,
    this.repeatable = false,
    this.cooldownDays = 0,
    this.weight = 10,
    this.chainOnly = false,
    this.turnDays = 0,
    this.varietyFamily = '',
    this.managedByDirector = false,
  });

  factory EventDef.fromContent(GameEvent e) => EventDef(
        id: e.id,
        title: e.title,
        description: e.description,
        category: e.category ?? EventCategory.random,
        minAge: e.minAge,
        maxAge: e.maxAge,
        requiredEducation: e.requiredEducation ?? Education.none,
        conditions: e.conditions,
        choices: [for (final c in e.choices) ChoiceDef.fromContent(c)],
        repeatable: e.repeatable,
        cooldownDays: e.cooldownDays,
        weight: e.weight,
        chainOnly: e.chainOnly,
        turnDays: e.turnDays,
      );

  final String id, title, varietyFamily;
  String description;
  final EventCategory category;
  final int minAge, maxAge, cooldownDays, weight, turnDays;
  final Education requiredEducation;
  final List<Condition> conditions;
  final List<ChoiceDef> choices;
  final bool repeatable, chainOnly, managedByDirector;

  ChoiceDef? findChoice(String id) {
    for (final c in choices) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Bir seçeneğin ekranda nasıl gösterileceği. UI koşul değerlendirmez, bunu okur.
class ChoiceView {
  const ChoiceView(this.id, this.text, this.cost, this.isAvailable, this.unmetReasons, this.hint);
  final String id, text, hint;
  final int cost;
  final bool isAvailable;
  final List<String> unmetReasons;
}
