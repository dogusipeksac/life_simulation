// Sahne yönlendirme: acil kararlar → gecikmeli sonuçlar → yaş dönümleri → ağırlıklı sahne.
// (Godot: Systems/LifeNarrativeDirector.cs)
//
// Seçim ve düğün gibi acil kararlar GameSession tarafından önce sunulur.

import '../content/models.dart';
import 'effects.dart';
import 'event_manager.dart';
import 'events.dart';
import 'rng.dart';
import 'state.dart';
import 'voice.dart';

const qualityNames = {
  'autonomy': 'Kendi yolun',
  'family': 'Aile bağları',
  'purpose': 'Hayat amacı',
  'community': 'Topluluk',
  'resilience': 'Dayanıklılık',
};

class NarrativeDirector {
  NarrativeDirector(Map<String, LifeScene> scenes) : scenes = Map.of(scenes);

  final Map<String, LifeScene> scenes;

  /// EventManager'a kaydedilen prototipler: kimlik/kategori bilgisi (çeşitlilik hesabı) için.
  Iterable<EventDef> prototypes() =>
      scenes.values.map((s) => _build(GameState(), s, track: false));

  bool isDirected(String id) => scenes.containsKey(id);

  EventDef? restore(GameState s, String id) {
    final scene = scenes[id];
    return scene != null && eligible(s, scene, ignoreHistory: true)
        ? _build(s, scene)
        : null;
  }

  EventDef? next(GameState s, GameRandom rng) {
    final memory = s.simulation;
    final due = [...memory.followUps]
      ..sort((a, b) => a.dueDay.compareTo(b.dueDay));
    for (final pending in due) {
      if (s.day < pending.dueDay) continue;
      final scene = scenes[pending.sceneId];
      if (scene == null || !eligible(s, scene, ignoreHistory: true)) {
        memory.followUps.remove(pending);
        continue;
      }
      memory.lastDecisionEcho = pending.cause;
      return _build(s, scene);
    }
    if (memory.directedAge != s.age) {
      memory.directedAge = s.age;
      memory.directedThisAge = 0;
    }
    if (memory.directedThisAge >= 4 || s.day - memory.lastDirectedDay < 14) {
      return null;
    }
    final available =
        scenes.values
            .where((sc) => !sc.followUpOnly && eligible(s, sc))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (available.isEmpty) return null;

    final milestones =
        available
            .where((sc) => sc.milestone && !s.completedEventIds.contains(sc.id))
            .toList()
          ..sort((a, b) {
            final p = b.priority.compareTo(a.priority);
            if (p != 0) return p;
            final r = (a.maxAge - s.age).compareTo(b.maxAge - s.age);
            // C# OrderBy kararlıdır; Dart sort değildir, eşitlikte ID sırası korunur.
            return r != 0 ? r : a.id.compareTo(b.id);
          });
    if (milestones.isNotEmpty) return _build(s, milestones.first);

    if (rng.nextDouble() > .72) return null;
    var total = 0.0;
    final weights = [
      for (final sc in available)
        () {
          final last = memory.domainLastDay[sc.domain] ?? -3650;
          final freshness = ((s.day - last) / 180.0).clamp(.12, 2.5);
          final relevance = sc.context.isNotEmpty ? 1.5 : 1.0;
          final need = switch (sc.domain) {
            'family' => 1 + (100 - memory.qualities['family']!) / 100.0,
            'work' => 1 + (100 - memory.qualities['purpose']!) / 100.0,
            _ => 1.0,
          };
          final w =
              (sc.priority < 1 ? 1 : sc.priority) *
              freshness *
              relevance *
              need;
          total += w;
          return w;
        }(),
    ];
    var roll = rng.nextDouble() * total;
    for (var i = 0; i < available.length; i++) {
      roll -= weights[i];
      if (roll <= 0) return _build(s, available[i]);
    }
    return _build(s, available.last);
  }

  bool eligible(GameState s, LifeScene scene, {bool ignoreHistory = false}) {
    if (s.age < scene.minAge || s.age > scene.maxAge) return false;
    if (scene.needs.any((f) => !s.flags.contains(f)) ||
        scene.forbids.any(s.flags.contains)) {
      return false;
    }
    final q = s.simulation.qualities;
    if (scene.minQualities.entries.any((e) => (q[e.key] ?? 50) < e.value) ||
        scene.maxQualities.entries.any((e) => (q[e.key] ?? 50) > e.value)) {
      return false;
    }
    final rel = s.relationships;
    final context = scene.context.startsWith('sector:')
        ? s.careerId != null &&
              s.simulation.careerTheme == scene.context.substring(7)
        : switch (scene.context) {
            'working' => s.careerId != null,
            'unemployed' =>
              s.age >= 18 && s.careerId == null && !s.flags.contains('retired'),
            'studying' => s.studyLevel != null,
            'partner' => rel.any((p) => p.alive && p.isPartner),
            'parent_alive' => rel.any((p) => p.alive && p.isParent),
            'care_parent' => rel.any(
              (p) => p.alive && p.isParent && p.ageNow(s) >= 70,
            ),
            'child' => rel.any((p) => p.alive && p.role == 'Çocuk'),
            'living_alone' => !s.flags.contains('married'),
            'debt' => s.money < 0,
            'inflation' => s.simulation.costIndex >= 115,
            'weak_jobs' => s.careerId != null && s.simulation.employment <= 40,
            'services_strain' => s.simulation.publicServices < 45,
            'retired' => s.flags.contains('retired'),
            'parent_lost' => rel.any((p) => !p.alive && p.isParent),
            '' => true,
            _ => false,
          };
    if (!context) return false;
    if (!ignoreHistory &&
        scene.milestone &&
        s.completedEventIds.contains(scene.id)) {
      return false;
    }
    final seen = s.eventLastSeenDay[scene.id];
    if (!ignoreHistory && seen != null && s.day - seen < scene.cooldownDays) {
      return false;
    }
    // Takip sahneleri (ignoreHistory) sınırdan muaf: bir kararın devamı her zaman gelir.
    if (!ignoreHistory && (s.eventShowCounts[scene.id] ?? 0) >= EventManager.repeatCapPerLife) {
      return false;
    }
    return scene.choices.any(
      (c) => c.cost <= 0 || s.money >= _price(s, c.cost),
    );
  }

  static int _price(GameState s, int amount) =>
      (amount * s.simulation.costIndex ~/ 100).clamp(0, 2147483647);

  EventDef _build(GameState s, LifeScene scene, {bool track = true}) {
    var description = fillScene(s, scene.text);
    final echo = s.simulation.domainEcho[scene.domain];
    if (!scene.followUpOnly && echo != null && echo.isNotEmpty) {
      description += '\n\nBu alanda aklında kalan: $echo';
    }
    if (s.simulation.lastDecisionEcho.isNotEmpty && scene.followUpOnly) {
      description =
          'Daha önce: ${s.simulation.lastDecisionEcho}\n\n$description';
    }
    final ev = EventDef(
      id: scene.id,
      title: scene.title,
      description: description,
      category: switch (scene.domain) {
        'work' => EventCategory.career,
        'school' => EventCategory.school,
        'health' => EventCategory.health,
        'family' || 'relationship' => EventCategory.social,
        'childhood' => EventCategory.childhood,
        _ => EventCategory.random,
      },
      minAge: scene.minAge,
      maxAge: scene.maxAge,
      chainOnly: true,
      managedByDirector: true,
      repeatable: !scene.milestone,
      turnDays: s.age < 6 ? 14 : 45,
      choices: [
        for (final c in scene.choices)
          ChoiceDef(
            id: c.id,
            text: fillScene(s, c.text),
            cost: _price(s, c.cost),
            result: fillScene(s, c.result),
            setFlags: c.set,
            removeFlags: c.remove,
            effects: [
              for (final e in c.stats.entries)
                if (enumByName(Stat.values, e.key) case final st?)
                  StatEffect(
                    st,
                    st == Stat.money
                        ? e.value * s.simulation.costIndex ~/ 100
                        : e.value,
                  ),
            ],
          ),
      ],
    );
    if (track) {
      s.simulation.currentSceneId = scene.id;
      s.simulation.currentSceneReason = scene.milestone
          ? 'Yaşam evrene ait önemli bir karar'
          : scene.followUpOnly
          ? 'Önceki seçiminin devamı'
          : '${scene.domain} · Hayatının koşullarına göre açıldı';
    }
    return ev;
  }

  void resolve(
    GameState s,
    EventDef ev,
    ChoiceDef choice,
    ChoiceResult result,
  ) {
    final scene = scenes[ev.id];
    if (scene == null) return;
    final option = scene.choices.firstWhere((c) => c.id == choice.id);
    final memory = s.simulation;
    for (final e in option.qualities.entries) {
      memory.qualities[e.key] = ((memory.qualities[e.key] ?? 50) + e.value)
          .clamp(0, 100);
    }
    for (final p in s.relationships.where((p) => p.alive)) {
      final delta = p.isPartner
          ? option.partnerBond
          : (p.isParent ? option.familyBond : 0);
      p.bond = (p.bond + delta).clamp(0, 100);
    }
    memory.domainLastDay[scene.domain] = s.day;
    memory.lastDirectedDay = s.day;
    if (memory.directedAge != s.age) {
      memory.directedAge = s.age;
      memory.directedThisAge = 0;
    }
    memory.directedThisAge++;
    memory.followUps.removeWhere(
      (f) => f.sceneId == scene.id && f.dueDay <= s.day,
    );
    memory.lastDecisionEcho = fillScene(s, option.result);
    memory.domainEcho[scene.domain] = memory.lastDecisionEcho;
    if (option.careerExit && s.careerId != null) {
      s.lastCareerId = s.careerId;
      s.careerId = null;
      s.careerLevel = 0;
      result.resultText += '\n\nBu işin sona erdi. Yeni iş ilanları ve yeniden öğrenme seçenekleri hayatında açıldı.';
    }
    if (option.next.isNotEmpty &&
        !memory.followUps.any((f) => f.sceneId == option.next)) {
      memory.followUps.add(
        DelayedLifeScene(
          sceneId: option.next,
          dueDay: s.day + (option.delayDays < 14 ? 14 : option.delayDays),
          cause: memory.lastDecisionEcho,
        ),
      );
    }
    if (option.qualities.isNotEmpty) {
      result.resultText +=
          '\n\n${option.qualities.entries.map((q) => '${qualityNames[q.key] ?? q.key} ${q.value >= 0 ? '+' : ''}${q.value}').join(' · ')}';
    }
  }
}
