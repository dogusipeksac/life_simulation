// Godot WeddingSystem: tören, masraf, takı ve eski kayıtların ilişkileri.
import '../content/models.dart';
import 'effects.dart';
import 'events.dart';
import 'rng.dart';
import 'state.dart';
import 'text.dart';

abstract final class Wedding {
  static const eventId = 'sim_v1_wedding';
  static int goldValue(GameState s) => 5000 * s.simulation.costIndex ~/ 100;
  static int cost(GameState s, String id) =>
      ({'civil': 8000, 'small': 60000, 'large': 180000}[id] ?? 0) *
      s.simulation.costIndex ~/
      100;
  static (bool, String) plan(GameState s, RelationshipPerson p) {
    if (s.age < 18 ||
        p.ageNow(s) < 18 ||
        !p.alive ||
        p.role != 'Partner' ||
        s.flags.contains('married'))
      return (false, 'Bu ilişki için evlilik planı açılamıyor.');
    if (s.simulation.wedding.pending)
      return (false, 'Zaten bir evlilik hazırlığınız var.');
    s.simulation.wedding = WeddingRecord()
      ..pending = true
      ..partnerId = p.id;
    p.role = 'Nişanlı';
    return (
      true,
      '${p.name} teklifini kabul etti. Sonraki hikâye kararında yalnız nikâh, küçük kutlama veya büyük düğün seçebilirsin. Takı ve aile desteği garanti değildir.',
    );
  }

  static EventDef? prepare(GameState s) {
    final w = s.simulation.wedding;
    if (!w.pending || s.isGameOver) return null;
    final p = s.relationships
        .where((p) => p.id == w.partnerId && p.alive && p.role == 'Nişanlı')
        .firstOrNull;
    if (p == null) {
      w.pending = false;
      return null;
    }
    final last = s.simulation.domainLastDay['wedding_postponed'];
    if (last != null && s.day - last < 90) return null;
    return EventDef(
      id: eventId,
      title: 'Nasıl bir başlangıç?',
      category: EventCategory.social,
      minAge: 18,
      maxAge: 100,
      repeatable: true,
      turnDays: 30,
      description:
          '${p.name} ile masaya oturup bir kâğıda iki sütun açıyorsunuz: «İstediğimiz» ve «Ödeyebildiğimiz». Ailenin beklentisi, arkadaşların ve ülkenin hayat pahalılığı aynı masada.\n\nNakit: ${formatMoney(s.money)}. Nikâh ${formatMoney(cost(s, 'civil'))}, küçük kutlama ${formatMoney(cost(s, 'small'))}, büyük düğün ${formatMoney(cost(s, 'large'))}.\n\nKatılanlar para veya oyun altını takabilir; kimsenin takı getirmesi garanti değil. Önce masrafı karşılamalısın. Takı değeri gerçek altın fiyatını temsil etmez.',
      choices: [
        for (final (id, text) in [
          ('civil', 'Yalnız nikâh · Sade bir başlangıç'),
          ('small', 'Küçük bir kutlama · Yakınlarımızla'),
          ('large', 'Büyük düğün · Kalabalık bir gün'),
        ])
          ChoiceDef(
            id: id,
            text: text,
            cost: cost(s, id),
            result: 'Birlikte yeni hayatınıza başladınız.',
          ),
        ChoiceDef(
          id: 'postpone',
          text: 'Şimdilik ertele, bütçeyi birlikte hazırlayın.',
          result: 'Düğün hazırlığını üç ay ertelediniz. Nişanınız sürüyor; masraf yapılmadı.',
        ),
      ],
    );
  }

  static void resolve(
    GameState s,
    String choice,
    GameRandom rng,
    EffectProcessor effects,
    ChoiceResult r,
  ) {
    final w = s.simulation.wedding;
    if (choice == 'postpone') {
      s.simulation.domainLastDay['wedding_postponed'] = s.day;
      return;
    }
    if (!w.pending) return;
    final p = s.relationships
        .where((p) => p.id == w.partnerId && p.alive && p.role == 'Nişanlı')
        .firstOrNull;
    if (p == null) return;
    w.pending = false;
    w.day = s.day;
    w.cost = cost(s, choice);
    w.ceremony = {
      'civil': 'Sadece nikâh',
      'small': 'Küçük kutlama',
      'large': 'Büyük düğün',
    }[choice]!;
    final guests = s.relationships.where(
      (g) =>
          g.alive &&
          g.id != p.id &&
          g.bond >= 45 &&
          !s.simulation.weddingGivers.contains(g.id) &&
          (choice != 'civil' || g.isParent),
    );
    for (final g in guests.take(choice == 'large' ? 10 : 5)) {
      final chance =
          ((g.generosity + g.bond + g.wealth) ~/ 3 -
                  s.simulation.socialTension ~/ 5)
              .clamp(5, 90);
      if (rng.rangeInt(1, 100) > chance || g.wealth < 15) continue;
      final units = (g.wealth ~/ 30).clamp(1, 100);
      if (rng.rangeInt(0, 1) == 0) {
        w.goldUnits += units;
        w.contributors.add('${g.name}: $units oyun altını');
      } else {
        final amount = units * 2500 * s.simulation.costIndex ~/ 100;
        w.cashGifts += amount;
        w.contributors.add('${g.name}: ${formatMoney(amount)}');
      }
      s.simulation.weddingGivers.add(g.id);
      g.wealth = (g.wealth - units * 2).clamp(5, 100);
    }
    w.goldValueAtWedding = w.goldUnits * goldValue(s);
    s.simulation.goldWallet += w.goldUnits;
    r.changes.add(effects.applyStat(s, Stat.money, w.cashGifts));
    r.changes.add(
      effects.applyStat(
        s,
        Stat.happiness,
        choice == 'civil'
            ? 6
            : choice == 'small'
            ? 9
            : 10,
      ),
    );
    p.role = 'Eş';
    p.bond = (p.bond + 5).clamp(0, 100);
    s.flags.add('married');
    s.flags.remove('dating');
    s.flags.remove('divorced');
    final gifts = w.contributors.isEmpty
        ? 'Bu kez takı veya nakit hediye gelmedi. Bütçeyi hediyeye güvenmeden kurmanız iyi oldu.'
        : w.contributors.join('\n');
    r.resultText =
        '${p.name} ile ${lowerInvariant(w.ceremony)} yaptınız. Kalabalık dağıldığında ilk kez yeni evinizin nasıl olacağını konuştunuz.\n\nÖdenen masraf: ${formatMoney(w.cost)}\nNakit takı: ${formatMoney(w.cashGifts)}\nAltın: ${w.goldUnits} oyun birimi (takı cüzdanında)\nNakit farkı: ${formatMoney(w.cashGifts - w.cost)}\n\n$gifts';
    s.simulation.lastDecisionEcho =
        '${w.ceremony} için ${formatMoney(w.cost)} ödediniz; takılar yeni ev masrafını tamamen karşılamak zorunda değil.';
    s.simulation.followUps.add(
      DelayedLifeScene(
        sceneId: 'lived_home_setup',
        dueDay: s.day + 45,
        cause: s.simulation.lastDecisionEcho,
      ),
    );
  }

  static void reconcile(GameState s) {
    if (s.flags.contains('married') &&
        !s.relationships.any((p) => p.alive && p.role == 'Eş')) {
      var p = s.relationships
          .where((p) => p.alive && ['Partner', 'Nişanlı'].contains(p.role))
          .firstOrNull;
      if (p == null) {
        p = RelationshipPerson(
          id: 'story_partner_${s.day}',
          name: 'Deniz',
          role: 'Eş',
          city: s.profile.birthplace,
          bond: 75,
        );
        s.relationships.add(p);
      }
      p.role = 'Eş';
    }
    if (s.flags.contains('dating') &&
        !s.flags.contains('married') &&
        !s.relationships.any(
          (p) => p.alive && ['Partner', 'Nişanlı'].contains(p.role),
        )) {
      s.relationships.add(
        RelationshipPerson(
          id: 'story_date_${s.day}',
          name: 'Ekin',
          role: 'Partner',
          city: s.profile.birthplace,
        ),
      );
    }
    if (!s.flags.contains('married') && s.flags.contains('divorced')) {
      for (final p in s.relationships.where((p) => p.role == 'Eş')) {
        p.role = 'Eski eş';
      }
    }
    final count = s.flags.contains('second_child')
        ? 2
        : s.flags.contains('has_child')
        ? 1
        : 0;
    for (var i = 0; i < count; i++) {
      if (s.relationships.any((p) => p.id == 'child_$i')) continue;
      final bornDay =
          s.eventLastSeenDay[i == 0
              ? 'social_new_baby'
              : 'social_second_child'] ??
          s.day;
      final bornAge = (s.age - ((s.day - bornDay).clamp(0, s.day) ~/ 365))
          .clamp(0, s.age);
      s.relationships.add(
        RelationshipPerson(
          id: 'child_$i',
          name: i == 0 ? 'Ada' : 'Bora',
          role: 'Çocuk',
          ageAtBirth: -bornAge,
          city: s.profile.birthplace,
          occupation: 'Büyüyor',
          education: 'Henüz başlamadı',
          bond: 80,
        ),
      );
    }
  }
}
