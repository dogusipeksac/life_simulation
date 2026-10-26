// Godot SocialLifeSystem: bütçe, bekleme süreleri ve ilişki eylemleri.
import '../content/models.dart';
import 'effects.dart';
import 'family.dart';
import 'rng.dart';
import 'state.dart';
import 'text.dart';
import 'wedding.dart';
import 'world.dart';

class LifeAction {
  const LifeAction(
    this.id,
    this.icon,
    this.title,
    this.description,
    this.category, [
    this.minAge = 0,
    this.cost = 0,
    this.health = 0,
    this.happiness = 0,
    this.education = 0,
    this.social = 0,
  ]);
  final String id, icon, title, description, category;
  final int minAge, cost, health, happiness, education, social;
}

abstract final class Social {
  static const activities = <LifeAction>[
    LifeAction(
      "toy",
      "✿",
      "Oyun zamanı",
      "Oyuncaklarla keşfet · +3 mutluluk, +2 zihin",
      "Zihin & beden",
      0,
      0,
      0,
      3,
      2,
      0,
    ),
    LifeAction(
      "read",
      "▤",
      "Kitap oku",
      "+5 zihin, +2 mutluluk",
      "Zihin & beden",
      6,
      0,
      0,
      2,
      5,
      0,
    ),
    LifeAction(
      "walk",
      "♧",
      "Yürüyüşe çık",
      "+4 sağlık, +2 mutluluk",
      "Zihin & beden",
      6,
      0,
      4,
      2,
      0,
      0,
    ),
    LifeAction(
      "music",
      "♫",
      "Enstrüman çalış",
      "+4 mutluluk, +2 sosyal · 250 ₺",
      "Zihin & beden",
      6,
      250,
      0,
      4,
      0,
      2,
    ),
    LifeAction(
      "sport",
      "◆",
      "Spor yap",
      "+6 sağlık · 150 ₺",
      "Zihin & beden",
      10,
      150,
      6,
      0,
      0,
      0,
    ),
    LifeAction(
      "care",
      "✦",
      "Kişisel bakım",
      "+4 görünüm, +2 mutluluk · 200 ₺",
      "Kişisel",
      12,
      200,
      0,
      2,
      0,
      0,
    ),
    LifeAction(
      "post",
      "◎",
      "İçerik paylaş",
      "Takipçi kazan · +2 sosyal",
      "Kişisel",
      13,
      0,
      0,
      0,
      0,
      2,
    ),
    LifeAction(
      "cinema",
      "▷",
      "Sinemaya git",
      "+6 mutluluk · 300 ₺",
      "Eğlence",
      10,
      300,
      0,
      6,
      0,
      0,
    ),
    LifeAction(
      "holiday",
      "☀",
      "Tatile çık",
      "+12 mutluluk, +3 sağlık · 5.000 ₺",
      "Eğlence",
      18,
      5000,
      3,
      12,
      0,
      0,
    ),
    LifeAction(
      "meet",
      "♡",
      "Yeni biriyle tanış",
      "Arkadaş çevreni genişlet · +3 sosyal",
      "İlişkiler",
      6,
      0,
      0,
      0,
      0,
      3,
    ),
    LifeAction(
      "pet",
      "♧",
      "Hayvan sahiplen",
      "Bir dosta yuva ol · +8 mutluluk · 1.500 ₺",
      "Alışveriş",
      18,
      1500,
      0,
      8,
      0,
      0,
    ),
    LifeAction(
      "car",
      "◇",
      "Araba al",
      "Kendi aracın · 600.000 ₺",
      "Alışveriş",
      18,
      600000,
      0,
      0,
      0,
      0,
    ),
    LifeAction(
      "house",
      "⌂",
      "Ev al",
      "Kendi evin · 2.500.000 ₺",
      "Alışveriş",
      18,
      2500000,
      0,
      0,
      0,
      0,
    ),
  ];
  static const interactions = <LifeAction>[
    LifeAction(
      "time",
      "♡",
      "Birlikte vakit geçir",
      "+8 ilişki, +3 mutluluk",
      "",
      0,
      0,
      0,
      3,
      0,
      0,
    ),
    LifeAction(
      "talk",
      "☏",
      "Sohbet et",
      "+6 ilişki, +2 sosyal",
      "",
      3,
      0,
      0,
      0,
      0,
      2,
    ),
    LifeAction(
      "compliment",
      "✦",
      "İltifat et",
      "+5 ilişki",
      "",
      5,
      0,
      0,
      0,
      0,
      0,
    ),
    LifeAction(
      "ask",
      "₺",
      "Harçlık iste",
      "Sonuç ilişkinize, cömertliğine ve imkânlarına bağlı",
      "",
      6,
      0,
      0,
      0,
      0,
      0,
    ),
    LifeAction(
      "give",
      "↗",
      "Para ver",
      "250 ₺ destek · +7 ilişki",
      "",
      16,
      250,
      0,
      0,
      0,
      0,
    ),
    LifeAction(
      "gift",
      "◇",
      "Hediye al",
      "500 ₺ · +12 ilişki",
      "",
      10,
      500,
      0,
      0,
      0,
      0,
    ),
    LifeAction(
      "coin",
      "◉",
      "Yazı tura oyna",
      "Bahissiz bir oyun · +4 ilişki, +2 mutluluk",
      "",
      5,
      0,
      0,
      2,
      0,
      0,
    ),
    LifeAction(
      "argue",
      "ϟ",
      "Tartış",
      "İlişkiniz ve mutluluğunuz zarar görebilir",
      "",
      8,
      0,
      0,
      -3,
      0,
      0,
    ),
    LifeAction(
      "date",
      "♥",
      "Çıkma teklif et",
      "Yetişkin bir arkadaşına duygularını aç · ilişki 70+",
      "",
      18,
      0,
      0,
      0,
      0,
      0,
    ),
    LifeAction(
      "marry",
      "∞",
      "Evlenme teklif et",
      "Tören ve bütçe kararını hikâyende planla · ilişki 85+",
      "",
      18,
      0,
      0,
      0,
      0,
      0,
    ),
    LifeAction(
      "breakup",
      "↘",
      "İlişkiyi bitir",
      "Partnerinle yollarınızı ayır",
      "",
      18,
      0,
      0,
      -5,
      0,
      0,
    ),
  ];
  static int remaining(GameState s) =>
      s.actionBudgetAge == s.age ? (12 - s.actionsUsed).clamp(0, 12) : 12;
  static String? blocked(GameState s, LifeAction a, [RelationshipPerson? p]) {
    if (s.isGameOver) return 'Bu hayat sona erdi.';
    if (s.age < a.minAge) return '${a.minAge} yaşında açılır.';
    if (p != null && !p.alive)
      return 'Bu kişi artık hayatta değil. Anısı günlüğünde yaşıyor.';
    if (remaining(s) == 0)
      return 'Bu yılın 12 etkinlik hakkını kullandın. Zamanı ilerlet.';
    final last = s.actionLastDay['${p?.id ?? 'activity'}:${a.id}'];
    if (last != null && s.day - last < 30)
      return '${30 - (s.day - last)} gün sonra yeniden yapabilirsin.';
    if (a.cost > 0 && s.money < a.cost)
      return '${formatMoney(a.cost)} nakit gerekli.';
    if (a.id == 'toy' && s.age >= 13)
      return 'Çocukluk etkinliği; diğer hobileri keşfet.';
    final flag = {
      'pet': 'pet_owner',
      'car': 'owns_car',
      'house': 'owns_house',
    }[a.id];
    if (flag != null && s.flags.contains(flag)) return 'Zaten hayatında var.';
    if (a.id == 'meet' &&
        s.relationships.where((p) => p.role == 'Arkadaş').length >= 8)
      return 'Arkadaş çevren dolu; mevcut dostluklarına zaman ayır.';
    if (a.id == 'ask' &&
        p != null &&
        ![
          'Anne',
          'Baba',
          'Koruyucu anne',
          'Koruyucu baba',
          'Büyükanne',
        ].contains(p.role))
      return 'Harçlık aile üyelerinden istenir.';
    if (a.id == 'date' && p != null) {
      if (p.role != 'Arkadaş' || p.ageNow(s) < 18)
        return 'Yetişkin arkadaşlar arasında kullanılabilir.';
      if (s.flags.contains('dating') || s.flags.contains('married'))
        return 'Önce mevcut ilişkini bitirmelisin.';
      if (p.bond < 70) return 'En az 70 ilişki gerekli.';
    }
    if (a.id == 'marry' && p != null && (p.role != 'Partner' || p.bond < 85))
      return 'Partnerinle en az 85 ilişki gerekli.';
    if (a.id == 'breakup' && p != null && !p.isPartner)
      return 'Yalnızca partnerin veya eşin için kullanılabilir.';
    return null;
  }

  static void consume(GameState s, String key) {
    if (s.actionBudgetAge != s.age) {
      s.actionBudgetAge = s.age;
      s.actionsUsed = 0;
    }
    s.actionsUsed++;
    s.actionLastDay[key] = s.day;
  }

  static (bool, String) perform(
    GameState s,
    EffectProcessor effects,
    String id, [
    String? personId,
  ]) {
    ensureFamily(s);
    final p = s.relationships.where((p) => p.id == personId).firstOrNull;
    if (personId != null && p == null) return (false, 'Kişi bulunamadı.');
    final a = (p == null ? activities : interactions)
        .where((a) => a.id == id)
        .firstOrNull;
    if (a == null) return (false, 'Etkinlik bulunamadı.');
    final reason = blocked(s, a, p);
    if (reason != null) return (false, reason);
    consume(s, '${p?.id ?? 'activity'}:$id');
    effects.applyStat(s, Stat.money, -a.cost);
    for (final (stat, amount) in [
      (Stat.health, a.health),
      (Stat.happiness, a.happiness),
      (Stat.education, a.education),
      (Stat.social, a.social),
    ]) {
      effects.applyStat(s, stat, amount);
    }
    var message = a.description;
    if (p != null) {
      final delta =
          {
            'time': 8,
            'talk': 6,
            'compliment': 5,
            'give': 7,
            'gift': 12,
            'coin': 4,
            'argue': -15,
            'date': 8,
            'marry': 5,
            'breakup': -25,
          }[id] ??
          0;
      p.bond = (p.bond + delta).clamp(0, 100);
      if (id == 'ask') {
        final accepted = p.bond >= 45 && p.generosity >= 35 && p.wealth >= 20;
        final amount = accepted ? 50 + p.wealth * 10 : 0;
        effects.applyStat(s, Stat.money, amount);
        p.bond = (p.bond - 2).clamp(0, 100);
        message = accepted
            ? '${p.name} sana ${formatMoney(amount)} harçlık verdi. İlişki −2.'
            : '${p.name} bu kez harçlık veremedi. İlişki −2. Birlikte vakit geçirmeyi deneyebilirsin.';
      } else {
        message = '${p.name}: ${lowerInvariant(a.title)}. ${a.description}.';
      }
      if (id == 'date') {
        p.role = 'Partner';
        s.flags.add('dating');
        message = '${p.name} teklifini kabul etti. Artık birliktesiniz!';
      }
      if (id == 'marry') message = Wedding.plan(s, p).$2;
      if (id == 'breakup') {
        s.simulation.wedding.pending = false;
        p.role = 'Arkadaş';
        s.flags.remove('dating');
        s.flags.remove('married');
        message = '${p.name} ile yollarınızı ayırdınız.';
      }
    } else {
      if (id == 'care') s.appearance = (s.appearance + 4).clamp(0, 100);
      if (id == 'post') {
        final gain = 15 + s.social * 2;
        s.followers = (s.followers + gain).clamp(0, 100000000);
        message = 'İçeriğin $gain yeni takipçi getirdi. +2 sosyal.';
      }
      if (id == 'meet') {
        final n = s.relationships.length;
        int pick(int salt, int count) => unsignedMod(
          splitMix(s.rngSeed + (salt - 1) * 0x9E3779B97F4A7C15),
          count,
        );
        const female = [
          'Elif',
          'Derya',
          'Selin',
          'Aylin',
          'Zeynep',
          'Defne',
          'Ece',
          'Mina',
        ];
        const male = [
          'Emre',
          'Mert',
          'Barış',
          'Kerem',
          'Can',
          'Arda',
          'Deniz',
          'Ege',
        ];
        const jobs = [
          ('Öğretmen', 'Üniversite'),
          ('Mühendis', 'Üniversite'),
          ('Esnaf', 'Lise'),
          ('Hemşire', 'Üniversite'),
          ('Aşçı', 'Meslek lisesi'),
          ('Tasarımcı', 'Üniversite'),
        ];
        final job = jobs[pick(110 + n, jobs.length)];
        final friend = RelationshipPerson(
          id: 'friend_$n',
          name: (n.isEven ? female : male)[pick(100 + n, 8)],
          gender: n.isEven ? 'Kadın' : 'Erkek',
          city: s.profile.birthplace,
          bond: 40,
          occupation: s.age < 18 ? 'Öğrenci' : job.$1,
          education: s.age < 18 ? 'Öğrenim görüyor' : job.$2,
        );
        s.relationships.add(friend);
        message =
            '${friend.name} ile tanıştın. Yeni arkadaşın İlişkiler bölümünde.';
      }
      final flag = {
        'pet': 'pet_owner',
        'car': 'owns_car',
        'house': 'owns_house',
      }[id];
      if (flag != null) s.flags.add(flag);
    }
    remember(s, p == null ? a.title : '${p.role} · ${a.title}', message);
    return (true, message);
  }

  static void birthday(GameState s) {
    ensureFamily(s);
    for (final p in s.relationships.where((p) => p.alive)) {
      if (p.role == 'Çocuk') {
        final age = p.ageNow(s);
        p.occupation = age < 6
            ? 'Oyunlarla büyüyor'
            : age < 18
            ? 'Öğrenci'
            : 'Kendi yolunu kuruyor';
        p.education = age < 6
            ? 'Henüz başlamadı'
            : age < 14
            ? 'Temel eğitim'
            : age < 18
            ? 'Ortaöğretim'
            : 'Kendi eğitim yolu';
      }
      p.health = (100 - (p.ageNow(s) - 40).clamp(0, 200)).clamp(0, 100);
      p.bond = (p.bond - 2).clamp(0, 100);
      if (p.ageNow(s) >= p.lifespan) {
        p.alive = false;
        if (p.isPartner) {
          if (p.role == 'Eş') s.flags.add('widowed');
          s.flags.remove('dating');
          s.flags.remove('married');
          s.simulation.wedding.pending = false;
        }
        remember(
          s,
          'Bir veda',
          '${p.name} ${p.ageNow(s)} yaşında hayatını kaybetti. Anıları seninle.',
        );
      }
    }
  }
}
