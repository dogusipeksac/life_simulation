// Karakter kimliği: doğum özellikleri, olay ağırlıkları, metin kişiselleştirme.
// Rastgelelik kullanmaz. (Godot: Core/LifeVoice.cs)

import '../content/models.dart';
import 'events.dart';
import 'state.dart';
import 'text.dart';

void applyBirthTraits(GameState s) {
  final (h, hp, e, so) = traits(s.profile.personality);
  s.health = (s.health + h).clamp(GameState.statMin, GameState.statMax);
  s.happiness = (s.happiness + hp).clamp(GameState.statMin, GameState.statMax);
  s.education = (s.education + e).clamp(GameState.statMin, GameState.statMax);
  s.social = (s.social + so).clamp(GameState.statMin, GameState.statMax);
}

(int, int, int, int) traits(String personality) => switch (personality) {
      'Sakin' => (4, 2, 0, -2),
      'Dışa dönük' => (0, 2, 0, 6),
      'Hayalperest' => (0, 4, 2, 0),
      _ => (0, 0, 4, 0),
    };

double categoryWeight(GameState s, EventCategory c) =>
    _personalityWeight(s.profile.personality, c) * _dreamWeight(s.profile.dream, c);

List<String> preferredGoalIds(String dream) => switch (dream) {
      'Yeni şeyler keşfetmek' => ['goal_see_world', 'goal_university'],
      'İnsanlara yardım etmek' => ['goal_social', 'goal_family', 'goal_parent'],
      'Bir eser bırakmak' => ['goal_career_peak', 'goal_university'],
      _ => [],
    };

String fillVoice(GameState s, String text) {
  if (text.isEmpty) return text;
  final p = s.profile;
  return text
      .replaceAll('{name}', s.playerName)
      .replaceAll('{caregiver}', p.caregiver)
      .replaceAll('{birthplace}', p.birthplace)
      .replaceAll('{family}', p.family)
      .replaceAll('{personality}', p.personality)
      .replaceAll('{dream}', p.dream);
}

/// Sahne metinleri için genişletilmiş doldurma (Godot: LifeNarrativeDirector.Fill).
String fillScene(GameState s, String text) {
  String person(String id, String fallback) {
    for (final p in s.relationships) {
      if (p.id == id) return p.name;
    }
    return fallback;
  }

  final partner = s.relationships.where((p) => p.alive && p.isPartner).firstOrNull?.name ?? 'birlikte olduğun kişi';
  final child = s.relationships.where((p) => p.role == 'Çocuk').firstOrNull?.name ?? 'çocuğun';
  final sim = s.simulation;
  return fillVoice(s, text)
      .replaceAll('{mother}', person('mother', 'annen'))
      .replaceAll('{father}', person('father', 'baban'))
      .replaceAll('{partner}', partner)
      .replaceAll('{child}', child)
      .replaceAll('{career}', sim.occupation.isNotEmpty ? sim.occupation : 'şu anki mesleğin')
      .replaceAll('{country}', sim.country)
      .replaceAll('{year}', '${sim.year(s)}');
}

String describeEvent(GameState s, EventDef ev, {Family? family}) {
  final body = fillVoice(s, ev.description);
  if (ev.id == 'baby_welcome') {
    final intro = family == null ? '' : '${family.name}: ${fillVoice(s, family.description)}\n\n';
    final p = s.profile;
    return '$intro${p.birthdayText} günü, ${p.birthplace} şehrinde, ${p.caregiver} yanında hikâyen başlıyor.\n\n$body';
  }
  final flavor = _flavor(s, ev.category);
  return flavor.isEmpty ? body : '$body\n\n$flavor';
}

String calmPeriod(GameState s) {
  final place = s.profile.birthplace;
  final caregiver = s.profile.caregiver;
  return switch (s.age) {
    < 2 => '$caregiver günlük bakımı sürdürdü. Günler yumuşak ve benzer geçti.',
    < 6 => switch (s.profile.personality) {
        'Sakin' => 'Sessiz öğleden sonralar birikti. Ev, tanıdık seslerle doldu.',
        'Dışa dönük' => 'Bahçede ve kapı önünde yeni yüzler gördün. Her selam küçük bir keşif oldu.',
        'Hayalperest' => 'Kendi uydurduğun hikâyeler, gerçek günden daha uzun sürdü.',
        _ => 'Her köşede yeni bir soru belirdi. Cevaplar yavaş yavaş birikti.',
      },
    < 18 => 'Okul, ev ve arkadaşlar birbirine karıştı. Sıradan günler de hayata yazıldı.',
    < 65 => switch (s.lifeFocus) {
        'Öğrenme' => 'Çalışmak ve öğrenmek günü doldurdu. Büyük bir dönüm noktası olmadı.',
        'İlişkiler' => 'Mesajlar, kısa ziyaretler ve tanıdık sohbetler haftayı taşıdı.',
        'Sağlık' => 'Rutinine sadık kaldın. Bedene iyi gelen küçük alışkanlıklar birikti.',
        _ => '$place ile kurduğun hayat, gürültüsüz bir tempo tutturdu.',
      },
    _ => 'Anılar masanın üzerine yayılmış gibi duruyordu. Gün yavaş, tanıdık ve senindi.',
  };
}

String lifeStory(GameState s, String occupation, {Family? origin}) {
  final born = origin == null ? '' : ' Kökeni: ${origin.name}.';
  final family = s.flags.contains('married')
      ? (s.flags.contains('has_child') ? 'Ev kurdu, yanında büyüyenler oldu.' : 'Bir yuva kurdu.')
      : 'Kendi yolunu yalnız da olsa sürdürdü.';
  return '${s.playerName}, ${s.profile.birthplace} doğumlu, ${lowerInvariant(s.profile.personality)} bir insandı.$born '
      'Küçükken hayali «${s.profile.dream}» idi. ${s.totalChoices} karar verdi; ${lowerInvariant(occupation)} olarak anıldı. $family';
}

List<String> recentMemories(GameState s, int count) {
  final out = <String>[];
  for (var i = s.journal.length - 1; i >= 0 && out.length < count; i--) {
    final e = s.journal[i];
    if (e.memory.isEmpty) continue;
    out.add('${e.title}: ${e.memory}');
  }
  return out;
}

String _flavor(GameState s, EventCategory c) => switch ((s.profile.personality, c)) {
      ('Meraklı', EventCategory.school || EventCategory.childhood) => 'Merakın seni ayrıntılara çekiyor.',
      ('Sakin', EventCategory.health) => 'Sakin durmak bu durumda sana doğal geliyor.',
      ('Dışa dönük', EventCategory.social) => 'İnsanların arasında olmak içini ısıtıyor.',
      ('Hayalperest', EventCategory.random || EventCategory.career) => 'Aklında başka bir son canlanıyor.',
      _ => '',
    };

double _personalityWeight(String p, EventCategory c) => switch ((p, c)) {
      ('Meraklı', EventCategory.school || EventCategory.childhood) => 1.3,
      ('Meraklı', EventCategory.random) => 1.15,
      ('Sakin', EventCategory.health) => 1.35,
      ('Sakin', EventCategory.childhood) => 1.15,
      ('Dışa dönük', EventCategory.social) => 1.4,
      ('Hayalperest', EventCategory.random) => 1.25,
      ('Hayalperest', EventCategory.career) => 1.15,
      _ => 1.0,
    };

double _dreamWeight(String d, EventCategory c) => switch ((d, c)) {
      ('Yeni şeyler keşfetmek', EventCategory.school || EventCategory.random) => 1.2,
      ('İnsanlara yardım etmek', EventCategory.social) => 1.25,
      ('İnsanlara yardım etmek', EventCategory.health) => 1.15,
      ('Bir eser bırakmak', EventCategory.career) => 1.25,
      ('Bir eser bırakmak', EventCategory.school) => 1.15,
      _ => 1.0,
    };
