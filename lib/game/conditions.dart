// Tiplendirilmiş koşulların değerlendirilmesi. (Godot: Systems/ConditionEvaluator.cs)

import '../content/models.dart';
import 'state.dart';
import 'text.dart';

/// Bayrak açıklamaları (flags.json): anahtar → (gerekli, yasak) metni.
typedef FlagTexts = Map<String, FlagInfo>;

bool isMet(GameState s, Condition c) => switch (c.type) {
      ConditionType.minStat => s.getStat(c.stat) >= c.value,
      ConditionType.maxStat => s.getStat(c.stat) <= c.value,
      ConditionType.hasFlag => s.flags.contains(c.key),
      ConditionType.notHasFlag => !s.flags.contains(c.key),
      ConditionType.hasCareer => s.careerId == c.key,
      ConditionType.noCareer => (s.careerId ?? '').isEmpty,
      ConditionType.minEducation => s.educationLevel.index >= c.value,
      ConditionType.minAge => s.age >= c.value,
      ConditionType.maxAge => s.age <= c.value,
      ConditionType.minCareerLevel => (s.careerId ?? '').isNotEmpty && s.careerLevel >= c.value,
      ConditionType.hadCareer => s.careerId == c.key || s.lastCareerId == c.key,
      ConditionType.minCompletedGoals => s.completedGoalIds.length >= c.value,
    };

bool allMet(GameState s, List<Condition> conditions) => conditions.every((c) => isMet(s, c));

List<String> describeUnmet(GameState s, List<Condition> conditions, FlagTexts flags) =>
    [for (final c in conditions) if (!isMet(s, c)) describeCondition(c, flags)];

String describeCondition(Condition c, FlagTexts flags) => switch (c.type) {
      ConditionType.minStat => '${statDisplay(c.stat)} en az ${c.value}',
      ConditionType.maxStat => '${statDisplay(c.stat)} en fazla ${c.value}',
      ConditionType.hasFlag => (flags[c.key]?.requiredText ?? '').isNotEmpty
          ? flags[c.key]!.requiredText
          : 'Gerekli durum: ${c.key}',
      ConditionType.notHasFlag => (flags[c.key]?.forbiddenText ?? '').isNotEmpty
          ? flags[c.key]!.forbiddenText
          : 'Uygun olmayan durum: ${c.key}',
      ConditionType.hasCareer => 'Gerekli meslek: ${c.key}',
      ConditionType.noCareer => 'Bir işte çalışmıyor olmalısın',
      ConditionType.minEducation => 'En az ${educationDisplay(Education.values[c.value])} mezunu',
      ConditionType.minAge => 'En az ${c.value} yaşında',
      ConditionType.maxAge => 'En fazla ${c.value} yaşında',
      ConditionType.minCareerLevel => 'Kariyerinde en az ${c.value}. basamak',
      ConditionType.hadCareer => 'Meslek geçmişi: ${c.key}',
      ConditionType.minCompletedGoals => 'En az ${c.value} hedef tamamlanmış',
    };
