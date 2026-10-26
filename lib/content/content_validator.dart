// İçerik doğrulayıcı: tools/build_content.py ve tools/build_life_scenes.py kurallarının
// Dart karşılığı. Ham JSON üzerinde çalışır ki bozuk bir dosya bütün hataları birden raporlasın.
// Mesajlar Godot aracıyla aynı Türkçe metinler.

import 'models.dart';

class ContentIssues {
  final List<String> errors = [];
  final List<String> warnings = [];

  void error(String where, String msg) => errors.add('HATA   $where: $msg');
  void warn(String where, String msg) => warnings.add('UYARI  $where: $msg');

  bool get ok => errors.isEmpty;

  @override
  String toString() => [...errors, ...warnings].join('\n');
}

const _eventKeys = {
  'id', 'title', 'category', 'description', 'minAge', 'maxAge', 'education', 'conditions', //
  'choices', 'repeatable', 'cooldownDays', 'weight', 'chainOnly', 'turnDays',
};
const _choiceKeys = {'id', 'text', 'effects', 'cost', 'requires', 'set', 'remove', 'result', 'next'};
const _goalKeys = {'id', 'title', 'description', 'conditions', 'reward'};
const _achievementKeys = {'id', 'title', 'description', 'conditions', 'atGameOver', 'secret'};
const _endingKeys = {'id', 'title', 'text', 'priority', 'conditions'};
const _flagKeys = {'key', 'required', 'forbidden', 'system'};
const _careerKeys = {
  'id', 'name', 'theme', 'description', 'minAge', 'education', 'minEducationStat', 'acceptChance', //
  'salary', 'raise', 'levels', 'promotionMonths', 'promotionStat', 'promotionMinStat', 'promotionChance',
  'healthPerYear', 'happinessPerYear',
};
const _familyKeys = {'id', 'name', 'origin', 'tier', 'description'};
const _lifeKeys = {
  'declineStartAge', 'baseYearlyLoss', 'extraLossEveryYears', 'recoveryPerYear', //
  'lowHappinessThreshold', 'lowHappinessExtraLoss', 'flagModifiers',
};

const _sceneKeys = {
  'Id', 'Title', 'Text', 'Domain', 'MinAge', 'MaxAge', 'Priority', 'CooldownDays', 'Milestone', //
  'FollowUpOnly', 'Context', 'Needs', 'Forbids', 'Choices', 'MinQualities', 'MaxQualities',
};
const _sceneChoiceKeys = {
  'Id', 'Text', 'Result', 'Cost', 'Stats', 'Qualities', 'Set', 'Remove', 'FamilyBond', //
  'PartnerBond', 'Next', 'DelayDays', 'CareerExit',
};
const _qualities = {'autonomy', 'family', 'purpose', 'community', 'resilience'};
const _stats = {'Health', 'Happiness', 'Education', 'Social', 'Money'};
const _contexts = {
  '', 'working', 'unemployed', 'studying', 'partner', 'parent_alive', 'care_parent', 'child', //
  'living_alone', 'debt', 'retired', 'parent_lost', 'inflation', 'weak_jobs', 'services_strain',
};

/// Ham içerik: dosya yolu → çözülmüş JSON.
class RawContent {
  RawContent({
    required this.flags,
    required this.careers,
    required this.families,
    required this.events,
    required this.goals,
    required this.achievements,
    required this.endings,
    required this.life,
    required this.scenes,
    required this.stories,
  });

  final List<Json> flags, careers, families, goals, achievements, endings, scenes;

  /// dosya adı (ör. "childhood.json") → olay listesi; sıralı işlenir.
  final Map<String, List<Json>> events;
  final Json life;

  /// dosya adı → kitap.
  final Map<String, Json> stories;
}

ContentIssues validateContent(RawContent c) {
  final e = ContentIssues();
  final flags = <String, Json>{};
  final flagsSet = <String, int>{};
  final flagsRead = <String, int>{};
  final careerIds = {for (final x in c.careers) x['id']};

  void checkKeys(Json obj, Set<String> allowed, String where) {
    for (final k in obj.keys) {
      if (!allowed.contains(k)) {
        e.error(where, "bilinmeyen alan '$k' (izin verilenler: ${(allowed.toList()..sort()).join(', ')})");
      }
    }
  }

  void useFlag(String flag, String where, {required bool set}) {
    if (!flags.containsKey(flag)) e.error(where, "bayrak '$flag' content/flags.json'da tanımlı değil (yazım hatası mı?)");
    final m = set ? flagsSet : flagsRead;
    m[flag] = (m[flag] ?? 0) + 1;
  }

  void conditions(Object? list, String where) {
    for (final text in (list as List? ?? const [])) {
      try {
        final cond = Condition.parse(text as String);
        switch (cond.type) {
          case ConditionType.hasFlag || ConditionType.notHasFlag:
            useFlag(cond.key, where, set: false);
          case ConditionType.hasCareer || ConditionType.hadCareer:
            if (!careerIds.contains(cond.key)) e.error(where, "bilinmeyen meslek '${cond.key}' (Data/Careers)");
          default:
        }
      } on FormatException catch (ex) {
        e.error(where, ex.message);
      }
    }
  }

  int intOf(Object? v, int fallback) => v == null ? fallback : (v as num).toInt();

  // Bayrak kataloğu
  for (final f in c.flags) {
    checkKeys(f, _flagKeys, 'flags.json/${f['key']}');
    if (flags.containsKey(f['key'])) e.error('flags.json', "'${f['key']}' iki kez tanımlı");
    flags[f['key'] as String] = f;
  }

  // Meslekler
  final seenCareers = <Object?>{};
  for (final car in c.careers) {
    final where = 'careers.json/${car['id'] ?? '?'}';
    if (!seenCareers.add(car['id'])) e.error(where, 'id tekrar ediyor');
    checkKeys(car, _careerKeys, where);
    for (final req in ['id', 'name', 'description', 'salary', 'levels']) {
      if (!car.containsKey(req)) e.error(where, "'$req' eksik");
    }
    final edu = car['education'] as String? ?? 'None';
    if (enumByName(Education.values, edu) == null) e.error(where, "eğitim '$edu' geçersiz");
    final stat = car['promotionStat'] as String? ?? 'Education';
    if (!_stats.contains(stat) || stat == 'Money') e.error(where, "terfi stat'ı '$stat' geçersiz");
    if ((car['levels'] as List? ?? const []).isEmpty) e.error(where, 'en az bir unvan olmalı');
    for (final k in ['minEducationStat', 'promotionMinStat']) {
      final v = intOf(car[k], 0);
      if (v < 0 || v > 100) e.error(where, '$k 0–100 olmalı');
    }
    for (final k in ['acceptChance', 'promotionChance']) {
      final v = intOf(car[k], 50);
      if (v < 1 || v > 100) e.error(where, '$k 1–100 olmalı');
    }
    if (intOf(car['salary'], 0) <= 0 || intOf(car['raise'], 0) < 0) {
      e.error(where, 'maaş pozitif, artış negatif olmayan bir sayı olmalı');
    }
  }

  // Aileler
  final familyIds = <Object?>{};
  final tiers = <String>{};
  for (final f in c.families) {
    final where = 'families.json/${f['id'] ?? '?'}';
    if (!familyIds.add(f['id'])) e.error(where, 'id tekrar ediyor');
    tiers.add('${f['tier']}');
    checkKeys(f, _familyKeys, where);
    for (final req in _familyKeys) {
      final v = f[req];
      if (v == null || v == '') e.error(where, "'$req' eksik");
    }
    if (enumByName(Wealth.values, f['tier'] as String?) == null) {
      e.error(where, "ekonomik durum '${f['tier']}' geçersiz (Poor, Low, Middle, Wealthy, Rich)");
    }
    final flag = 'origin_${f['origin']}';
    if (!flags.containsKey(flag)) e.error(where, "köken bayrağı '$flag' content/flags.json'da tanımlı değil");
  }
  for (final w in Wealth.values) {
    final name = w.name[0].toUpperCase() + w.name.substring(1);
    if (!tiers.contains(name)) {
      e.error('families.json', "'$name' durumunda hiç aile yok; kader zarı bu durumu seçerse aile bulunamaz");
    }
  }

  // Olaylar
  final byId = <String, Json>{};
  final events = <Json>[];
  for (final file in c.events.keys.toList()..sort()) {
    for (final ev in c.events[file]!) {
      final where = 'events/$file/${ev['id'] ?? '?'}';
      if (byId.containsKey(ev['id'])) e.error(where, 'EventId tekrar ediyor');
      byId['${ev['id']}'] = ev;
      events.add(ev);
      checkKeys(ev, _eventKeys, where);
      for (final req in ['id', 'title', 'category', 'description', 'choices']) {
        if (!ev.containsKey(req)) e.error(where, "'$req' eksik");
      }
      if (enumByName(EventCategory.values, ev['category'] as String?) == null) {
        e.error(where, "kategori '${ev['category']}' geçersiz (Childhood, School, Career, Health, Social, Random)");
      }
      final minAge = intOf(ev['minAge'], 0), maxAge = intOf(ev['maxAge'], 100);
      if (minAge > maxAge) e.error(where, 'minAge $minAge > maxAge $maxAge');
      final choices = (ev['choices'] as List? ?? const []).cast<Json>();
      if (choices.length < 2 || choices.length > 4) e.error(where, '${choices.length} seçenek var; 2–4 olmalı');
      if (ev['education'] != null && enumByName(Education.values, ev['education'] as String) == null) {
        e.error(where, "eğitim '${ev['education']}' geçersiz");
      }
      conditions(ev['conditions'], where);
      final seen = <Object?>{};
      for (final (i, ch) in choices.indexed) {
        final cw = '$where/${ch['id'] ?? i}';
        checkKeys(ch, _choiceKeys, cw);
        final cid = ch['id'] as String? ?? '';
        if (cid.isEmpty || !seen.add(cid)) e.error(cw, 'seçenek id boş ya da tekrar ediyor');
        if ((ch['text'] as String? ?? '').isEmpty || (ch['result'] as String? ?? '').isEmpty) {
          e.error(cw, "'text' ve 'result' zorunlu");
        }
        (ch['effects'] as Map? ?? const {}).forEach((stat, amount) {
          if (!_stats.contains(stat)) {
            e.error(cw, "bilinmeyen stat '$stat'");
          } else if ((amount as num).toInt() == 0) {
            e.warn(cw, '$stat etkisi 0');
          }
        });
        if (intOf(ch['cost'], 0) < 0) e.error(cw, 'cost negatif olamaz');
        conditions(ch['requires'], cw);
        for (final f in [...?(ch['set'] as List?), ...?(ch['remove'] as List?)]) {
          useFlag(f as String, cw, set: true);
        }
      }
    }
  }
  final referenced = <String>{};
  for (final ev in events) {
    for (final ch in (ev['choices'] as List? ?? const []).cast<Json>()) {
      final next = ch['next'] as String?;
      if (next == null || next.isEmpty) continue;
      referenced.add(next);
      if (!byId.containsKey(next)) e.error('events/${ev['id']}/${ch['id']}', "next '$next' bulunamadı");
    }
  }
  for (final ev in events) {
    if (ev['chainOnly'] == true && !referenced.contains(ev['id'])) {
      e.error('events/${ev['id']}', 'chainOnly ama hiçbir seçenek buna bağlanmıyor');
    }
  }

  // Hedefler, başarımlar, sonlar
  for (final (file, items, keys) in [
    ('goals.json', c.goals, _goalKeys),
    ('achievements.json', c.achievements, _achievementKeys),
    ('endings.json', c.endings, _endingKeys),
  ]) {
    final ids = <Object?>{};
    for (final item in items) {
      final where = '$file/${item['id'] ?? '?'}';
      if (!ids.add(item['id'])) e.error(where, 'id tekrar ediyor');
      checkKeys(item, keys, where);
      if ((item['id'] ?? '') == '' || (item['title'] ?? '') == '') e.error(where, "'id' ve 'title' zorunlu");
      conditions(item['conditions'], where);
    }
    if (file == 'endings.json' && !items.any((x) => (x['conditions'] as List? ?? const []).isEmpty)) {
      e.error(file, 'koşulsuz (varsayılan) bir son olmalı');
    }
  }

  // Yaşlanma
  checkKeys(c.life, _lifeKeys, 'life.json');
  for (final flag in (c.life['flagModifiers'] as Map? ?? const {}).keys) {
    useFlag(flag as String, 'life.json', set: false);
  }

  // Bayrak tutarlılığı (yalnızca uyarı)
  flags.forEach((key, f) {
    if (f['system'] == true) return;
    final read = flagsRead[key] ?? 0, set = flagsSet[key] ?? 0;
    if (read > 0 && set == 0) e.warn('flags.json', "'$key' koşullarda okunuyor ama hiçbir seçenek koymuyor");
    if (read == 0 && set == 0) e.warn('flags.json', "'$key' hiç kullanılmıyor");
  });

  _validateScenes(c.scenes, e);
  c.stories.forEach((file, book) => _validateStory(file, book, e));
  return e;
}

/// tools/build_life_scenes.py ile aynı kurallar. Sahne bayrakları flags.json'a bağlı değildir
/// (Godot aracı da denetlemez).
void _validateScenes(List<Json> scenes, ContentIssues e) {
  const w = 'life_scenes.json';
  final ids = <String>{};
  int i(Object? v, int fb) => v == null ? fb : (v as num).toInt();
  for (final s in scenes) {
    final id = s['Id'] as String? ?? '';
    final where = '$w/$id';
    if (!id.startsWith('lived_') || !ids.add(id)) e.error(where, 'id geçersiz ya da tekrar ediyor');
    final unknown = s.keys.toSet().difference(_sceneKeys);
    if (unknown.isNotEmpty) e.error(where, 'bilinmeyen alan: ${unknown.join(', ')}');
    final minAge = i(s['MinAge'], -1), maxAge = i(s['MaxAge'], 101);
    if (!(0 <= minAge && minAge <= maxAge && maxAge <= 100)) e.error(where, 'yaş aralığı geçersiz ($minAge–$maxAge)');
    if ((s['Title'] ?? '') == '' || (s['Text'] ?? '') == '') e.error(where, 'başlık ya da metin eksik');
    final ctx = s['Context'] as String? ?? '';
    if (!_contexts.contains(ctx) && !ctx.startsWith('sector:')) e.error(where, "bağlam '$ctx' geçersiz");
    final choices = (s['Choices'] as List? ?? const []).cast<Json>();
    if (choices.length < 2 || choices.length > 4) e.error(where, '${choices.length} seçenek var; 2–4 olmalı');
    if (!choices.any((c) => i(c['Cost'], 0) == 0)) e.error(where, 'en az bir ücretsiz seçenek olmalı');
    for (final k in ['MinQualities', 'MaxQualities']) {
      final bad = (s[k] as Map? ?? const {}).keys.toSet().difference(_qualities);
      if (bad.isNotEmpty) e.error(where, '$k içinde bilinmeyen nitelik: ${bad.join(', ')}');
    }
    final choiceIds = <String>{};
    for (final c in choices) {
      final cw = '$where/${c['Id'] ?? '?'}';
      final unknownC = c.keys.toSet().difference(_sceneChoiceKeys);
      if (unknownC.isNotEmpty) e.error(cw, 'bilinmeyen alan: ${unknownC.join(', ')}');
      final cid = c['Id'] as String? ?? '';
      if (cid.isEmpty || !choiceIds.add(cid)) e.error(cw, 'seçenek id boş ya da tekrar ediyor');
      if ((c['Text'] ?? '') == '' || (c['Result'] ?? '') == '') e.error(cw, "'Text' ve 'Result' zorunlu");
      final cost = i(c['Cost'], 0);
      if (cost < 0 || cost > 10000000) e.error(cw, 'maliyet 0–10.000.000 olmalı');
      (c['Stats'] as Map? ?? const {}).forEach((k, v) {
        if (!_stats.contains(k)) e.error(cw, "bilinmeyen stat '$k'");
        if (v is! int || (k != 'Money' && v.abs() > 15)) e.error(cw, '$k etkisi geçersiz ($v)');
      });
      (c['Qualities'] as Map? ?? const {}).forEach((k, v) {
        if (!_qualities.contains(k)) e.error(cw, "bilinmeyen nitelik '$k'");
        if (v is! int || v.abs() > 15) e.error(cw, '$k nitelik etkisi geçersiz ($v)');
      });
    }
  }
  final referenced = <String>{};
  for (final s in scenes) {
    for (final c in (s['Choices'] as List? ?? const []).cast<Json>()) {
      final next = c['Next'] as String? ?? '';
      if (next.isEmpty) continue;
      referenced.add(next);
      if (!ids.contains(next)) e.error('$w/${s['Id']}', "devam sahnesi '$next' bulunamadı");
    }
  }
  // Ev kurma sahnesini düğün sistemi zamanlar; diğer takip sahnelerine bir seçenek bağlanmalı.
  for (final s in scenes) {
    if (s['FollowUpOnly'] == true && !referenced.contains(s['Id']) && s['Id'] != 'lived_home_setup') {
      e.error('$w/${s['Id']}', 'takip sahnesi ama hiçbir seçenek buna bağlanmıyor');
    }
  }
  for (var age = 0; age <= 100; age++) {
    final covered = scenes.any((s) => i(s['MinAge'], 0) <= age && age <= i(s['MaxAge'], 100) && s['FollowUpOnly'] != true);
    if (!covered) e.error(w, '$age yaşı için yazılı sahne yok');
  }
}

/// Hikâye kitabı bütünlüğü: başlangıç düğümü, bütün Next hedefleri, bölüm numaraları ve stat adları.
void _validateStory(String file, Json book, ContentIssues e) {
  final where = 'stories/$file';
  final nodes = (book['Nodes'] as Map? ?? const {}).cast<String, Json>();
  final statNames = (book['StatNames'] as Map? ?? const {}).keys.toSet();
  final chapters = (book['Chapters'] as List? ?? const []).length;
  if ((book['Id'] ?? '') == '' || (book['Title'] ?? '') == '') e.error(where, "'Id' ve 'Title' zorunlu");
  final start = book['Start'] as String? ?? 'start';
  if (!nodes.containsKey(start)) e.error(where, "başlangıç düğümü '$start' yok");
  nodes.forEach((id, n) {
    final nw = '$where/$id';
    final choices = (n['Choices'] as List? ?? const []).cast<Json>();
    final ending = (n['Ending'] as String? ?? '').isNotEmpty;
    if (!ending && choices.isEmpty) e.error(nw, 'son olmayan düğümde seçenek yok');
    final chapter = (n['Chapter'] as num? ?? 1).toInt();
    if (chapter < 1 || chapter > chapters) e.error(nw, 'bölüm $chapter geçersiz (1–$chapters)');
    for (final c in choices) {
      final next = c['Next'] as String? ?? '';
      if (!nodes.containsKey(next)) e.error(nw, "Next '$next' bulunamadı");
      final need = c['NeedStat'] as String? ?? '';
      if (need.isNotEmpty && !statNames.contains(need)) e.error(nw, "NeedStat '$need' StatNames içinde yok");
      for (final k in (c['Effects'] as Map? ?? const {}).keys) {
        if (!statNames.contains(k)) e.error(nw, "etki '$k' StatNames içinde yok");
      }
    }
  });
}
