// Kader zarı, doğum bayrakları ve aile üyeleri.
// (Godot: Systems/FamilySystem.cs, SocialLifeSystem.EnsureFamily)

import '../content/models.dart';
import 'rng.dart';
import 'state.dart';

/// Yoksul, dar gelirli, orta halli, varlıklı, zengin (%).
const tierWeights = [15, 30, 35, 15, 5];

/// Önce ekonomik durum ağırlıklı, sonra o durumdaki ailelerden biri eşit şansla.
/// Yalnızca seed'e bağlı; oyunun RNG'sini tüketmez.
Family? rollFamily(List<Family> families, int seed) {
  if (families.isEmpty) return null;
  final sorted = [...families]..sort((a, b) => a.id.compareTo(b.id));
  final a = splitMix(seed ^ 0xFA111E5), b = splitMix(a);
  final total = tierWeights.fold(0, (x, y) => x + y);
  var roll = unsignedMod(a, total);
  var tier = Wealth.middle;
  for (var i = 0; i < tierWeights.length; i++) {
    if (roll < tierWeights[i]) {
      tier = Wealth.values[i];
      break;
    }
    roll -= tierWeights[i];
  }
  var pool = sorted.where((f) => f.tier == tier).toList();
  if (pool.isEmpty) pool = sorted;
  return pool[unsignedMod(b, pool.length)];
}

/// Doğumda bir kez: aile, cinsiyet ve doğum mevsimi bayrakları.
void applyBirth(GameState s, Family? family) {
  if (family != null) {
    s.profile.familyId = family.id;
    s.profile.wealth = family.tier ?? Wealth.middle;
    s.flags.add(family.originFlag);
  }
  s.flags.add('family_${s.profile.wealth.name}');
  if (s.profile.gender == 'Kadın') {
    s.flags.add('gender_female');
  } else if (s.profile.gender == 'Erkek') {
    s.flags.add('gender_male');
  }
  s.flags.add('born_${s.profile.birthSeason}');
}

const _femaleNames = ['Elif', 'Derya', 'Selin', 'Aylin', 'Zeynep', 'Defne', 'Ece', 'Mina'];
const _maleNames = ['Emre', 'Mert', 'Barış', 'Kerem', 'Can', 'Arda', 'Deniz', 'Ege'];
const _jobs = [
  ('Öğretmen', 'Üniversite'), ('Mühendis', 'Üniversite'), ('Esnaf', 'Lise'),
  ('Hemşire', 'Üniversite'), ('Aşçı', 'Meslek lisesi'), ('Tasarımcı', 'Üniversite'),
];

int _pick(int seed, int salt, int count) {
  var x = seed + salt * 0x9E3779B97F4A7C15;
  x = (x ^ (x >>> 30)) * 0xBF58476D1CE4E5B9;
  x = (x ^ (x >>> 27)) * 0x94D049BB133111EB;
  return unsignedMod(x ^ (x >>> 31), count);
}

void ensureFamily(GameState s) {
  if (s.relationshipsInitialized) return;
  s.relationshipsInitialized = true;
  final trimmed = s.playerName.trim();
  final surname = trimmed.contains(' ') ? trimmed.split(' ').last : '';
  final suffix = surname.isNotEmpty ? ' $surname' : '';
  final count = s.profile.family == 'Tek ebeveynli aile' ? 1 : 2;
  for (var i = 0; i < count; i++) {
    final job = _jobs[_pick(s.rngSeed, 40 + i, _jobs.length)];
    final role = s.profile.family == 'Koruyucu aile'
        ? (i == 0 ? 'Koruyucu anne' : 'Koruyucu baba')
        : (i == 0 ? 'Anne' : 'Baba');
    s.relationships.add(RelationshipPerson(
      id: i == 0 ? 'mother' : 'father',
      role: role,
      gender: i == 0 ? 'Kadın' : 'Erkek',
      name: (i == 0 ? _femaleNames : _maleNames)[_pick(s.rngSeed, 10 + i, 8)] + suffix,
      city: s.profile.birthplace,
      occupation: job.$1,
      education: job.$2,
      ageAtBirth: 23 + _pick(s.rngSeed, 20 + i, 15),
      lifespan: 78 + _pick(s.rngSeed, 30 + i, 20),
      bond: 60 + _pick(s.rngSeed, 50 + i, 25),
      generosity: 30 + _pick(s.rngSeed, 60 + i, 61),
      wealth: 10 + s.profile.wealth.index * 18,
      personality: i == 0 ? 'Şefkatli' : 'Sakin',
    ));
  }
  if (s.profile.family == 'Geniş aile') {
    s.relationships.add(RelationshipPerson(
      id: 'grandmother', name: 'Gülay$suffix', role: 'Büyükanne', gender: 'Kadın', ageAtBirth: 54,
      lifespan: 93, city: s.profile.birthplace, occupation: 'Emekli', education: 'İlkokul', bond: 82,
    ));
  }
  for (final p in s.relationships) {
    p.alive = p.ageNow(s) < p.lifespan;
  }
}
