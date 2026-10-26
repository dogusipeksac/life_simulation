// Godot CareerSystem, EducationSystem, EconomySystem ve GoalSystem kuralları.
import '../content/game_content.dart';
import '../content/models.dart';
import 'conditions.dart';
import 'effects.dart';
import 'rng.dart';
import 'state.dart';
import 'text.dart';
import 'voice.dart';

class CareerView {
  const CareerView(this.career, this.blockers, this.chance, this.current);
  final Career career;
  final List<String> blockers;
  final int chance;
  final bool current;
  bool get canApply => !current && blockers.isEmpty;
}

int salaryAt(Career c, int level) =>
    c.salary +
    c.raise * (level.clamp(1, c.levels.isEmpty ? 1 : c.levels.length) - 1);
String titleAt(Career c, int level) =>
    c.levels.isEmpty ? c.name : c.levels[level.clamp(1, c.levels.length) - 1];

class Progression {
  Progression(this.content, this.effects);
  final GameContent content;
  final EffectProcessor effects;
  List<Career> get careers => content.careers.values.toList()
    ..sort((a, b) {
      final edu = a.education!.index.compareTo(b.education!.index);
      return edu == 0 ? a.salary.compareTo(b.salary) : edu;
    });
  int salary(GameState s) {
    final c = content.careers[s.careerId];
    return c == null ? 0 : salaryAt(c, s.careerLevel);
  }

  List<String> blockers(GameState s, Career c) => [
    if (s.age < c.minAge) 'En az ${c.minAge} yaşında olmalısın',
    if (s.age >= 65) 'Emeklilik yaşındasın',
    if (s.educationLevel.index < c.education!.index)
      '${educationDisplay(c.education!)} mezunu olmalısın',
    if (s.education < c.minEducationStat) 'Eğitim en az ${c.minEducationStat}',
  ];
  int chance(GameState s, Career c) =>
      (c.acceptChance + ((s.education - c.minEducationStat).clamp(0, 100) ~/ 2))
          .clamp(5, 95);
  int cooldown(GameState s, String id, [int days = 90]) =>
      s.careerApplicationDay.containsKey(id)
      ? (days - (s.day - s.careerApplicationDay[id]!)).clamp(0, days)
      : 0;
  List<CareerView> views(GameState s) => [
    for (final c in careers)
      CareerView(
        c,
        [
          ...blockers(s, c),
          if (cooldown(s, c.id) > 0)
            'Tekrar başvurmak için ${cooldown(s, c.id)} gün bekle',
        ],
        chance(s, c),
        s.careerId == c.id,
      ),
  ];
  int _order(GameState s, String id) {
    var hash =
        0xCBF29CE484222325 ^ s.rngSeed ^ ((s.day ~/ 180) * 0x9E3779B97F4A7C15);
    for (final c in id.codeUnits) {
      hash = (hash ^ c) * 1099511628211;
    }
    return hash;
  }

  List<CareerView> openings(GameState s) {
    final all = views(s)
      ..sort((a, b) {
        final x = _order(s, a.career.id), y = _order(s, b.career.id);
        return (x ^ -0x8000000000000000).compareTo(y ^ -0x8000000000000000);
      });
    final eligible = all
        .where((v) => !v.current && blockers(s, v.career).isEmpty)
        .toList();
    return [
      ...all.where((v) => v.current),
      ...eligible.take(3),
      ...all
          .where((v) => !v.current && blockers(s, v.career).isNotEmpty)
          .take(2 + (3 - eligible.length).clamp(0, 3)),
    ];
  }

  void _start(GameState s, Career c) {
    s.careerId = s.lastCareerId = c.id;
    s.careerLevel = 1;
    s.careerStartDay = s.careerLevelStartDay = s.day;
  }

  (bool, String) apply(GameState s, String id, GameRandom rng) {
    final c = content.careers[id];
    if (c == null) return (false, 'Böyle bir meslek yok.');
    final blocked = blockers(s, c);
    if (blocked.isNotEmpty || s.careerId == id) {
      return (
        false,
        blocked.isEmpty ? 'Zaten bu işte çalışıyorsun.' : blocked.join(', '),
      );
    }
    if (cooldown(s, id) > 0) {
      return (
        false,
        'Bu işe yakın zamanda başvurdun. ${cooldown(s, id)} gün sonra tekrar dene.',
      );
    }
    if (rng.rangeInt(1, 100) > chance(s, c)) {
      s.careerApplicationDay[id] = s.day;
      return (false, '${c.name} başvurun olumsuz sonuçlandı.');
    }
    _start(s, c);
    return (
      true,
      'Tebrikler! Artık ${titleAt(c, 1)} olarak çalışıyorsun. Aylık maaşın ${formatMoney(salaryAt(c, 1))}.',
    );
  }

  (bool, String) fate(GameState s, GameRandom rng) {
    if (s.careerId != null) {
      return (false, 'Kaderine güvenmek için önce işinden ayrılmalısın.');
    }
    final wait = cooldown(s, '~kader', 365);
    if (wait > 0) {
      return (
        false,
        'Kader yakın zamanda konuştu. $wait gün sonra tekrar dene.',
      );
    }
    final pool = careers
        .where((c) => blockers(s, c).isEmpty && cooldown(s, c.id) == 0)
        .toList();
    if (pool.isEmpty) return (false, 'Şu an sana açık bir kapı yok.');
    final c = pool[rng.rangeInt(0, pool.length - 1)];
    s.careerApplicationDay['~kader'] = s.day;
    _start(s, c);
    return (
      true,
      'Kader seni ${c.name} yolculuğuna çıkardı. Artık ${titleAt(c, 1)} olarak çalışıyorsun; aylık maaşın ${formatMoney(salaryAt(c, 1))}.',
    );
  }

  void quit(GameState s) {
    if (s.careerId == null) return;
    s.careerApplicationDay[s.careerId!] = s.day;
    s.lastCareerId = s.careerId;
    s.careerId = null;
    s.careerLevel = 0;
  }

  void promote(GameState s, GameRandom rng, TurnReport? report) {
    final c = content.careers[s.careerId];
    if (c == null ||
        s.careerLevel >= c.levels.length ||
        (s.day - s.careerLevelStartDay) ~/ 30 < c.promotionMonths ||
        s.getStat(c.promotionStat!) < c.promotionMinStat) {
      return;
    }
    if (rng.rangeInt(1, 100) > c.promotionChance) return;
    s.careerLevel++;
    s.careerLevelStartDay = s.day;
    report?.notes.add(
      'Terfi aldın: ${titleAt(c, s.careerLevel)}! Yeni maaşın ${formatMoney(salary(s))}.',
    );
  }

  void careerBirthday(GameState s, TurnReport? report) {
    if (s.age >= 65 && !s.flags.contains('retired')) {
      final pay = salary(s);
      s.pensionMonthly = pay > 0
          ? (pay * 60 ~/ 100).clamp(7000, 0x7FFFFFFFFFFFFFFF)
          : 7000;
      if (s.careerId != null) s.lastCareerId = s.careerId;
      s.careerId = null;
      s.careerLevel = 0;
      s.flags.add('retired');
      report?.notes.add(
        'Emekli oldun. Aylık emekli maaşın ${formatMoney(s.pensionMonthly)}.',
      );
      return;
    }
    final c = content.careers[s.careerId];
    if (c != null) {
      effects.applyStat(s, Stat.health, c.healthPerYear);
      effects.applyStat(s, Stat.happiness, c.happinessPerYear);
    }
  }

  // EducationConfig.tres: level, required, name, start, duration, graduation, flag.
  static const stages = [
    (Education.primary, Education.none, 'İlköğretim', 6, 8, 0, ''),
    (Education.highSchool, Education.primary, 'Lise', 14, 4, 25, ''),
    (
      Education.university,
      Education.highSchool,
      'Üniversite',
      18,
      4,
      45,
      'enroll_university',
    ),
    (
      Education.master,
      Education.university,
      'Yüksek Lisans',
      22,
      2,
      65,
      'enroll_master',
    ),
  ];
  void enroll(GameState s, TurnReport? r) {
    if (s.studyLevel != null) return;
    for (final st in stages) {
      if (st.$2 != s.educationLevel ||
          s.flags.contains('failed_${educationName(st.$1)}')) {
        continue;
      }
      if (st.$7.isEmpty
          ? s.age >= st.$4 && s.age < st.$4 + st.$5
          : s.flags.remove(st.$7)) {
        s.studyLevel = st.$1;
        s.studyStartAge = st.$7.isEmpty ? st.$4 : s.age;
        s.flags.add('studying');
        r?.notes.add('${st.$3} eğitimine başladın.');
        return;
      }
    }
  }

  void schoolBirthday(GameState s, TurnReport? r) {
    final st = stages.where((st) => st.$1 == s.studyLevel).firstOrNull;
    if (st != null) {
      effects.applyStat(s, Stat.education, 4);
      if (s.age - s.studyStartAge >= st.$5) {
        s.studyLevel = null;
        s.flags.remove('studying');
        if (s.education >= st.$6) {
          s.educationLevel = st.$1;
          r?.notes.add('${st.$3} mezunu oldun!');
        } else {
          s.flags.add('failed_${educationName(st.$1)}');
          r?.notes.add('${st.$3} eğitimini tamamlayamadın.');
        }
      }
    }
    enroll(s, r);
  }

  List<(String, int)> budget(GameState s) {
    final lines = <(String, int)>[];
    final c = content.careers[s.careerId];
    final studying = s.studyLevel != null;
    int share(int value) =>
        value * [50, 75, 100, 150, 250][s.profile.wealth.index] ~/ 100;
    if (c != null) {
      lines.add(('Maaş (${titleAt(c, s.careerLevel)})', salary(s)));
    }
    if (s.pensionMonthly > 0) lines.add(('Emekli maaşı', s.pensionMonthly));
    if (s.age < 18) {
      if (s.age >= 10) lines.add(('Harçlık', share(300)));
      return lines;
    }
    if (studying) {
      lines.add(('Aile / burs desteği', share(11000)));
    } else if (s.careerId == null && s.pensionMonthly == 0) {
      lines.add(('Aile / işsizlik desteği', share(6000)));
    }
    final earned = lines.fold(0, (v, l) => v + l.$2);
    if (c != null || s.pensionMonthly > 0) {
      lines.add(('Yaşam tarzı harcamaları', -earned * 20 ~/ 100));
    }
    final percent = studying ? 60 : 100;
    for (final (name, amount, required, waived) in const [
      ('Kira', 9000, '', 'owns_house'),
      ('Faturalar', 2000, '', ''),
      ('Mutfak', 4500, '', ''),
      ('Ulaşım', 1500, '', 'owns_car'),
      ('Diğer harcamalar', 1500, '', ''),
      ('Araç masrafları', 4000, 'owns_car', ''),
      ('Çocuk masrafları', 6000, 'has_child', ''),
      ('İkinci çocuk masrafları', 4000, 'second_child', ''),
    ]) {
      if ((required.isEmpty || s.flags.contains(required)) &&
          (waived.isEmpty || !s.flags.contains(waived))) {
        lines.add((name, -amount * percent ~/ 100));
      }
    }
    if (s.money < 0) {
      lines.add(('Borç faizi', -((-s.money * 15 + 999) ~/ 1000)));
    }
    final expenses = -lines.where((l) => l.$2 < 0).fold(0, (v, l) => v + l.$2);
    final w = s.simulation, base = salary(s);
    final adjustment =
        earned * (w.costIndex - 100) ~/ 100 +
        base * (w.employment - 55) ~/ 250 -
        expenses * (w.costIndex - 100) ~/ 100 +
        (studying ? (w.publicServices - 55) * 40 : 0);
    if (adjustment != 0) {
      lines.add(('Ülke koşulları (oyun modeli)', adjustment));
    }
    return lines;
  }

  bool processMonth(GameState s, int month, TurnReport? r) {
    if (month <= s.lastEconomyProcessedMonth) return false;
    s.lastEconomyProcessedMonth = month;
    for (final l in budget(s)) {
      final change = effects.applyStat(s, Stat.money, l.$2);
      if (r != null) {
        if (change.applied > 0) {
          r.income += change.applied;
        } else {
          r.expenses -= change.applied;
        }
      }
    }
    if (s.money >= 0) {
      final recovered = s.flags.remove('in_debt');
      if (s.flags.remove('bankrupt')) s.flags.add('recovered_from_bankruptcy');
      if (recovered) r?.notes.add('Borçlarının hepsini kapattın.');
    } else {
      if (s.flags.add('in_debt')) {
        r?.notes.add('Hesabın eksiye düştü; artık borç faizi işliyor.');
      }
      if (s.money <= -150000) {
        if (s.flags.add('bankrupt')) {
          r?.notes.add(
            'Borç limitine dayandın. Ödeyemediğin faturalar birikiyor.',
          );
        }
        effects.applyStat(s, Stat.happiness, -3);
      } else {
        s.flags.remove('bankrupt');
      }
    }
    return true;
  }

  void assignGoals(GameState s, GameRandom rng) {
    if (s.activeGoalIds.isNotEmpty || content.goals.isEmpty) return;
    final pool = [...content.goals]..sort((a, b) => a.id.compareTo(b.id));
    final preferred = pool
        .where((g) => preferredGoalIds(s.profile.dream).contains(g.id))
        .toList();
    if (preferred.isNotEmpty) {
      final g = preferred[rng.rangeInt(0, preferred.length - 1)];
      s.activeGoalIds.add(g.id);
      pool.remove(g);
    }
    while (s.activeGoalIds.length < 3 && pool.isNotEmpty) {
      s.activeGoalIds.add(pool.removeAt(rng.rangeInt(0, pool.length - 1)).id);
    }
  }

  void checkGoals(GameState s, TurnReport? r) {
    for (final g in content.goals.where(
      (g) =>
          s.activeGoalIds.contains(g.id) && !s.completedGoalIds.contains(g.id),
    )) {
      if (!allMet(s, g.conditions)) continue;
      s.completedGoalIds.add(g.id);
      effects.applyStat(s, Stat.happiness, g.rewardHappiness);
      r?.notes.add('Hedef tamamlandı: ${g.title}!');
    }
  }
}
