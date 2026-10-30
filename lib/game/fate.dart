// Kader: yeni bir hayatın oyuncunun seçmediği her şeyi. Ad, cinsiyet ve doğum günü önerilir
// (oyuncu değiştirebilir); doğum yeri, aile ortamı, bakım veren, mizaç ve hayal yalnızca
// seed'e bağlı atanır ve yeniden atılamaz. Oyunun RNG dizisini tüketmez.

import 'dart:math';

import 'state.dart';

const _female = ['Elif', 'Zeynep', 'Defne', 'Ece', 'Selin', 'Asya', 'Lara', 'Nehir', 'Ela', 'Mira', 'Duru', 'İpek'];
const _male = ['Kerem', 'Emir', 'Arda', 'Can', 'Mert', 'Yusuf', 'Ege', 'Aras', 'Kaan', 'Bora', 'Efe', 'Alp'];
const _neutral = ['Deniz', 'Umut', 'Derin', 'Ada', 'Evren', 'Çağ', 'Toprak', 'Göknur', 'Bilge', 'Ilgın'];
const _surnames = ['Yılmaz', 'Kaya', 'Demir', 'Şahin', 'Çelik', 'Aydın', 'Arslan', 'Doğan', 'Kılıç', 'Aslan', 'Öztürk', 'Kurt', 'Tekin', 'Erdem'];
const birthplaces = [
  'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Trabzon', 'Antalya', 'Eskişehir', 'Gaziantep', //
  'Diyarbakır', 'Samsun', 'Mardin', 'Çanakkale', 'Kars', 'Muğla', 'Konya', 'Rize', 'Edirne', 'Hatay',
];
const personalities = ['Meraklı', 'Sakin', 'Dışa dönük', 'Hayalperest'];
const dreams = ['Kendi yolumu bulmak', 'Yeni şeyler keşfetmek', 'İnsanlara yardım etmek', 'Bir eser bırakmak'];

/// (aile ortamı, ağırlık, olası bakım verenler)
const _families = [
  ('Çekirdek aile', 50, ['Annem ve babam', 'Ailem']),
  ('Geniş aile', 25, ['Anneannem', 'Babaannem', 'Ailem']),
  ('Tek ebeveynli aile', 15, ['Annem', 'Babam']),
  ('Koruyucu aile', 10, ['Koruyucu ailem']),
];

Random _rng(int seed, int salt) => Random((seed ^ (salt * 0x9E3779B1)) & 0x7FFFFFFF);

/// Önerilen kimlik: oyuncu değiştirebilir.
({String name, String gender, int day, int month}) suggestIdentity(int seed, {int variant = 0}) {
  final r = _rng(seed, 11 + variant * 7);
  final gender = CharacterProfile.genders[r.nextInt(CharacterProfile.genders.length)];
  final first = switch (gender) {
    'Kadın' => _female,
    'Erkek' => _male,
    _ => _neutral,
  };
  final month = 1 + r.nextInt(12);
  return (
    name: '${first[r.nextInt(first.length)]} ${_surnames[r.nextInt(_surnames.length)]}',
    gender: gender,
    month: month,
    day: 1 + r.nextInt(CharacterProfile.daysInMonth(month)),
  );
}

/// Verilen cinsiyete uygun yeni bir ad önerisi.
String suggestName(String gender, int seed, int variant) {
  final r = _rng(seed, 101 + variant);
  final first = switch (gender) {
    'Kadın' => _female,
    'Erkek' => _male,
    _ => _neutral,
  };
  return '${first[r.nextInt(first.length)]} ${_surnames[r.nextInt(_surnames.length)]}';
}

/// Kaderin belirlediği özellikler profile yazılır (ad, cinsiyet, doğum günü, tempo dokunulmaz).
void applyFate(CharacterProfile p, int seed) {
  final r = _rng(seed, 3);
  p.birthplace = birthplaces[r.nextInt(birthplaces.length)];
  final total = _families.fold(0, (a, f) => a + f.$2);
  var roll = r.nextInt(total);
  for (final (name, weight, caregivers) in _families) {
    if (roll < weight) {
      p.family = name;
      p.caregiver = caregivers[r.nextInt(caregivers.length)];
      break;
    }
    roll -= weight;
  }
  p.personality = personalities[r.nextInt(personalities.length)];
  p.dream = dreams[r.nextInt(dreams.length)];
}

/// Dönem önceliği: 90 günde bir kaderle değişir, oyuncu seçmez.
String rollFocus(int seed, int period) => lifeFocuses[_rng(seed, 900 + period).nextInt(lifeFocuses.length)];
