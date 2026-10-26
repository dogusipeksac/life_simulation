// Godot LifeWorldSystem: kurgusal ülke, seçim ve bütçe koşulları.
import '../content/models.dart';
import 'effects.dart';
import 'events.dart';
import 'rng.dart';
import 'state.dart';

abstract final class World {
  static const electionId = 'sim_v1_election';
  static const platforms = {
    'services': 'Kamusal hizmetler',
    'enterprise': 'Üretim ve girişim',
    'environment': 'Yaşam alanları',
  };
  static bool electionOpen(GameState s) =>
      s.simulation.electionClosesDay >= 0 &&
      s.day <= s.simulation.electionClosesDay;
  static void birthday(GameState s, GameRandom rng, TurnReport? r) {
    final w = s.simulation;
    if (w.lastWorldAge >= s.age) return;
    w.lastWorldAge = s.age;
    final prices = rng.rangeInt(-1, 4);
    w.costIndex = (w.costIndex + prices).clamp(80, 220);
    w.employment = (w.employment + rng.rangeInt(-4, 4)).clamp(10, 90);
    w.socialTension = (w.socialTension + rng.rangeInt(-4, 4)).clamp(0, 100);
    if (s.age % 5 == 0) {
      w.electionNumber++;
      w.electionOpenedAge = s.age;
      w.electionClosesDay = s.day + 90;
      r?.notes.add(
        s.age >= 18
            ? 'Ülkede seçim dönemi başladı. Hikâyende oy verme kararı açıldı.'
            : 'Ülkede seçim dönemi başladı; evde konuşulanlar değişiyor.',
      );
    }
    if (prices >= 3) {
      r?.notes.add(
        'Hayat pahalılığı arttı; aylık bütçenin ülke koşulları satırını kontrol edebilirsin.',
      );
    }
  }

  static void month(GameState s, GameRandom rng, TurnReport? r) {
    final w = s.simulation;
    if (w.electionClosesDay < 0 || s.day <= w.electionClosesDay) return;
    final winner = platforms.keys.elementAt(
      rng.rangeInt(0, platforms.length - 1),
    );
    w.government = platforms[winner]!;
    switch (winner) {
      case 'services':
        w.publicServices += 7;
        w.employment--;
        w.costIndex += 2;
      case 'enterprise':
        w.employment += 7;
        w.publicServices -= 2;
        w.socialTension += 3;
      case 'environment':
        w.publicServices += 3;
        w.socialTension -= 5;
        w.costIndex++;
    }
    w.ensureValid();
    w.elections.add(
      CivicRecord.fromJson({
        'Election': w.electionNumber,
        'Year': w.year(s),
        'Vote': w.lastVotedElection == w.electionNumber
            ? w.lastVote
            : 'Oy kullanmadı / yaşı uygun değildi',
        'Winner': w.government,
      }),
    );
    w.electionClosesDay = -1;
    final text =
        'Kurgusal seçim sonuçlandı: ${w.government} yönetimi göreve geldi. Kamu hizmetleri, iş koşulları ve bütçe dengesi zamanla değişecek.';
    remember(s, 'Ülkede yeni dönem', text);
    r?.notes.add(text);
  }

  static EventDef? election(GameState s) {
    final w = s.simulation;
    if (s.age < 18 ||
        !electionOpen(s) ||
        w.lastVotedElection == w.electionNumber) {
      return null;
    }
    return EventDef(
      id: electionId,
      title: 'Sandığa giderken',
      category: EventCategory.random,
      minAge: 18,
      maxAge: 100,
      repeatable: true,
      turnDays: 14,
      description:
          '${w.year(s)} · ${w.country}. Mahalle okulunda sandık kuruluyor. Ailen ve iş arkadaşların farklı önceliklerden söz ediyor. Sen hangi konuya ağırlık vereceksin?\n\nBu ülke, adaylar ve ekonomik sonuçlar oyunun kurgusudur. Oyun hiçbir gerçek partiye oy vermeni önermez; tek oyun ülke sonucunu belirlemez.',
      choices: [
        for (final e in platforms.entries)
          ChoiceDef(
            id: e.key,
            text: '${e.value} programını tercih et.',
            result: 'Oyunu kullandın. Sonuç diğer seçmenlerle birlikte belirlenecek.',
          ),
        ChoiceDef(
          id: 'abstain',
          text: 'Bu seçimde oy kullanma.',
          result: 'Sandığa gitmedin. Ülkenin yeni dönemi senin hayatını da etkileyecek.',
        ),
      ],
    );
  }

  static void vote(GameState s, String choice, ChoiceResult r) {
    final w = s.simulation;
    w.lastVotedElection = w.electionNumber;
    w.lastVote = platforms[choice] ?? 'Oy kullanmadı';
    if (choice != 'abstain') {
      w.qualities['community'] = ((w.qualities['community'] ?? 50) + 3).clamp(
        0,
        100,
      );
    }
    r.resultText +=
        '\n\nTercihin: ${w.lastVote}. Sonuçlar seçim dönemi kapanınca hayat günlüğüne yazılacak.';
  }
}

void remember(GameState s, String title, String memory) {
  s.journal.add(
    JournalEntry(age: s.age, day: s.day, title: title, memory: memory),
  );
  if (s.journal.length > 300) s.journal.removeAt(0);
}
