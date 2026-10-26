// Sürümlü, belirlenimci olay kombinasyonları; ID'ler kayıtlar için sabit kalmalı.
// (Godot: Systems/LifeEventCatalog.cs — metinler ve sayılar birebir)

import '../content/models.dart';
import 'events.dart';
import 'text.dart';

const lifeCatalogEventCount = 6000;

const _activities = [
  ['Uçurtma yapımı', 'Hazine avı', 'Kukla gösterisi', 'Lego şehri', 'Masal saati', 'Resim atölyesi', 'Tohum yetiştirme', 'Ritim oyunu', 'Kağıt tekne yarışı', 'Bilmece kulübü'],
  ['Bilim projesi', 'Okul gazetesi', 'Münazara hazırlığı', 'Kodlama atölyesi', 'Tarih araştırması', 'Matematik kulübü', 'Dil pratiği', 'Kitap tartışması', 'Coğrafya sunumu', 'Tiyatro provası'],
  ['Portfolyo çalışması', 'Meslek buluşması', 'Sunum pratiği', 'İş fikri atölyesi', 'Özgeçmiş hazırlığı', 'Dijital beceri kursu', 'Müşteri iletişimi eğitimi', 'Proje planlama', 'Ustalık atölyesi', 'Mülakat provası'],
  ['Yürüyüş grubu', 'Esneme çalışması', 'Dengeli mutfak atölyesi', 'Nefes molası', 'Uyku günlüğü', 'Hafif egzersiz', 'Duruş farkındalığı', 'Dinlenme planı', 'Sağlıklı alışkanlık buluşması', 'Rahatlama atölyesi'],
  ['Fotoğraf kulübü', 'Mahalle korosu', 'Masa oyunu buluşması', 'Gönüllü ekip', 'Film tartışması', 'Şiir dinletisi', 'Dans atölyesi', 'Sohbet çemberi', 'Öykü paylaşımı', 'El işi buluşması'],
  ['Kent tarihi keşfi', 'Çizim günlüğü', 'Yeni tarif denemesi', 'Koleksiyon buluşması', 'Bitki bakımı', 'Tamir atölyesi', 'Geri dönüşüm projesi', 'Yerel kültür araştırması', 'Müzik keşfi', 'Anı albümü'],
];

const _settings = [
  'Mahalle merkezinde', 'Küçük bir atölyede', 'Kütüphanenin etkinlik salonunda', 'Bir kültür merkezinde', 'Yakındaki bir dernek binasında',
  'Çevrim içi bir buluşmada', 'Belediyenin etkinlik alanında', 'Ortak çalışma salonunda', 'Semt evinde', 'Bir eğitim merkezinde',
];

const _situations = [
  ('İlk adım', 'Katılanların çoğu ilk kez deniyor; herkes biraz çekingen.', 1, 40),
  ('Dar bütçe', 'Malzemeler sınırlı; ekip masrafı paylaşmak için bir çözüm arıyor.', 2, 100),
  ('Son dakika', 'Hazırlık süresi kısalmış; hızlı bir plan yapılması gerekiyor.', 3, 60),
  ('Yeni yüzler', 'Birbirini tanımayan katılımcılar birlikte çalışmayı öğreniyor.', 1, 50),
  ('İki farklı fikir', 'Grup iki yaklaşım arasında bölünmüş; birinin uzlaşma önermesi gerekiyor.', 2, 80),
  ('Beklenmedik ilgi', 'Beklenenden fazla kişi katılmış; küçük ekipler kurulması gerekiyor.', 3, 70),
  ('İkinci deneme', 'İlk deneme iyi gitmemiş; ekip hatalarını değerlendirip yeniden başlamak istiyor.', 2, 50),
  ('Paylaşma zamanı', 'Çalışmayı başka katılımcılara anlatma fırsatı doğuyor.', 3, 90),
  ('Sessiz başlangıç', 'Küçük grup kendi hızında ilerliyor; denemek için bolca zaman var.', 1, 30),
  ('Ortak hedef', 'Herkesin küçük bir katkıyla tamamlayabileceği ortak bir çalışma hazırlanıyor.', 2, 60),
];

String _l(String s) => lowerInvariant(s);

final _practice = <String Function(String)>[
  (t) => '$t için kendi köşende alıştırma yap',
  (t) => '«$t» adımlarını defterine yaz, sonra dene',
  (t) => 'Kimse bakmadan ${_l(t)} üzerinde bir tur at',
  (t) => 'Kısa bir video izle, sonra ${_l(t)} için tek başına tekrar et',
  (t) => 'Hata yapmaktan çekinmeden ${_l(t)} pratiği yap',
  (t) => 'En kolay parçadan başla, ${_l(t)} işini böl',
  (t) => 'Eve bir örnek götür, ${_l(t)} için akşam çalış',
  (t) => 'Süreyi kendin tut, ${_l(t)} temposunu yavaşlat',
];

final _practiceResult = <String Function(String, String)>[
  (t, p) => '«$t» üzerinde kendi hızında ilerledin. $p kalabalık kalırken sen küçük bir beceri çıkardın.',
  (t, p) => 'Defterindeki sıra işe yaradı. «$t» artık ${_l(p)} duyduğun rastgele bir öğüt değil.',
  (t, p) => 'Kalabalıktan uzak durunca ellerin rahatladı. «$t» sende yavaş yavaş oturdu.',
  (t, p) => 'İzlediğini hemen denedin. «$t» ilk seferde olmadı; ikincide ${_l(p)} işe yarayan bir hareket buldun.',
  (t, p) => 'Bozulan denemeyi saklamadın. «$t» hatası sana bir sonraki adımı gösterdi.',
  (t, p) => 'İşi parçalara bölünce ${_l(t)} gözünde büyümeyi bıraktı.',
  (t, p) => 'Akşamki tekrar, ${_l(p)} kalan yarım işi kapattı.',
  (t, _) => 'Acele etmeyince «$t» ritmi sende kaldı. Yarın aynı yerden devam edebilirsin.',
];

final _together = <String Function(String)>[
  (t) => 'Bir eş bul, ${_l(t)} görevini ikiye böl',
  (t) => 'Yanındakine sor, «$t» için nöbetleşe çalışın',
  (t) => 'Utangaç bir katılımcıyı davet et, birlikte deneyin',
  (t) => 'Karşılıklı anlatın: sen ${_l(t)}, o kendi bildiğini',
  (t) => 'Küçük bir ekip kur, sırayla ${_l(t)} adımını deneyin',
  (t) => 'Bir tanıdığın temposuna uy, işi paylaş',
  (t) => 'Yüksek sesle düşün, ${_l(t)} kararını birlikte verin',
  (t) => 'Biten kısmı birine göster, onun fikriyle düzelt',
];

final _togetherResult = <String Function(String, String)>[
  (t, p) => '«$t» sırasında iş bölündü. $p kurulan tanışıklık sana cesaret verdi.',
  (t, p) => 'Nöbetleşe çalışmak ${_l(t)} yükünü hafifletti. $p bir isim daha öğrendin.',
  (t, _) => 'Davet ettiğin kişi de çekiniyormuş. «$t» ikinize de daha kolay geldi.',
  (t, p) => 'Anlatırken ${_l(t)} kendin de netleşti. $p kısa bir sohbet uzadı.',
  (t, _) => 'Sıra sende bittiğinde ekip alkışlamadı; sadece «oldu» dedi. Bu da yeterdi.',
  (t, p) => 'Başkasının temposu önce zorladı, sonra «$t» ortak bir ritme oturdu.',
  (t, _) => 'Yüksek sesle konuşunca yanlış anlaşılma düzeldi. Karar ikinizin oldu.',
  (t, p) => 'Gösterdiğin iş eleştirildi, sonra düzeldi. $p «$t» artık sadece senin değildi.',
];

final _lead = <String Function(String)>[
  (t) => 'Malzemeyi karşıla, ${_l(t)} hazırlığını üstlen',
  (t) => 'Eksik parçaları tamamla, grubu ${_l(t)} için toparla',
  (t) => 'Küçük bir bütçeyle ${_l(t)} masasını sen kur',
  (t) => 'Dağılan planı yaz, herkese ${_l(t)} görevini ver',
  (t) => 'Geç kalanlar için ${_l(t)} özetini hazırla',
  (t) => 'Yer ayarla, ${_l(t)} sırasını görünür kıl',
  (t) => 'Malzeme listesini çıkar, eksikleri sen kapat',
  (t) => 'Zor kısmı üstlen, başkaları ${_l(t)} kenarında kalsın',
];

final _leadResult = <String Function(String, String)>[
  (t, w) => '«$t» hazırlığı sende toplandı. $w yüzünden yoruldun; ekip ise işini yetiştirdi.',
  (t, w) => 'Eksikleri kapatınca ${_l(t)} yürüdü. $w stresini sen taşıdın.',
  (t, _) => 'Masayı kurmak görünmez bir işti. «$t» başladığında herkes yerini buldu.',
  (t, w) => 'Yazdığın plan tartışmayı kesti. $w koşullarında «$t» yine de bitti.',
  (t, _) => 'Özetin geç kalanları içeri aldı. «$t» bölünmeden devam etti.',
  (t, _) => 'Sıra duvarda durunca kimse birbirinin önüne geçmedi.',
  (t, w) => 'Liste işe yaradı. $w maliyetini cebinden karşıladın.',
  (t, _) => 'Zor parçayı bitirdiğinde omuzların ağrıdı. «$t» ise dağılmadı.',
];

final _rest = <String Function(String)>[
  (t) => 'Bu kez ${_l(t)} için kalma, kendine zaman ayır',
  (t) => 'Kapıdan bak, «$t» bugün sana göre değil',
  (t) => 'Nazikçe veda et, enerjini yarına sakla',
  (t) => 'Sadece selam ver, ${_l(t)} kalabalığına girme',
  (t) => 'Ev işini öne al, bu oturumu kaçır',
  (t) => 'Bir süre izle, sonra ${_l(t)} yerinden kalk',
  (t) => 'Başka bir gün sözü ver, bugün dinlen',
  (t) => 'Kalabalığı duy, ${_l(t)} için yine de dışarıda kal',
];

final _restResult = <String Function(String, String)>[
  (t, _) => '«$t» fırsatını bu kez geçtin. Boş kalan zaman sakinleşmeni sağladı; grubun deneyimi sende yok.',
  (t, p) => '$p kapısında durup döndün. «$t» sensiz de yürüdü.',
  (t, _) => 'Vedan kısa oldu. Yarın ${_l(t)} için daha dinç olabileceğini düşündün.',
  (t, _) => 'Selamın ardından uzaklaştın. Kimse üstüne gelmedi.',
  (t, _) => 'Evdeki iş bitti. «$t» aklının bir köşesinde kaldı.',
  (t, p) => 'Bir süre izlemek yetti. $p gürültüsü dışarıda kaldı.',
  (t, _) => 'Söz verdin. «$t» takviminde duruyor; bugün değil.',
  (t, _) => 'Dışarıda kalmak da bir karardı. Bedenin bunu sevdi, merakın biraz kırıldı.',
];

Stat _sideStat(int category, int voice) => switch (category + voice) {
      0 || 4 => Stat.happiness,
      1 || 5 => Stat.education,
      2 => Stat.social,
      _ => Stat.health,
    };

ChoiceDef _choice(String id, String text, String result, Stat gain, int amount, Stat other, int delta,
        {int cost = 0, List<Condition> requirements = const []}) =>
    ChoiceDef(
      id: id,
      text: text,
      result: result,
      effects: [StatEffect(gain, amount), StatEffect(other, delta)],
      cost: cost,
      requirements: requirements,
    );

Iterable<EventDef> buildLifeCatalog() sync* {
  for (var category = 0; category < _activities.length; category++) {
    for (var activity = 0; activity < _activities[category].length; activity++) {
      for (var setting = 0; setting < _settings.length; setting++) {
        for (var situation = 0; situation < _situations.length; situation++) {
          final (twistTitle, twistText, effort, twistCost) = _situations[situation];
          final title = _activities[category][activity];
          final focus = switch (category) {
            0 => Stat.happiness,
            1 || 2 => Stat.education,
            3 => Stat.health,
            4 => Stat.social,
            _ => Stat.happiness,
          };
          final voice = (activity * 3 + setting + situation * 5) % _practice.length;
          final place = _settings[setting];
          final socialMin = 15 + effort * 5;
          yield EventDef(
            id: 'life_v1_${category}_${activity}_${setting}_$situation',
            varietyFamily: 'life_v1_${category}_${activity}_',
            title: '$title: $twistTitle',
            description: '$place «$title» için bir etkinlik düzenleniyor. $twistText Nasıl katılacaksın?',
            category: EventCategory.values[category],
            minAge: switch (category) { 0 => 6, 1 => 6, 2 => 18, _ => 12 },
            maxAge: switch (category) { 0 => 13, 1 => 22, 2 => 64, _ => 100 },
            choices: [
              _choice('practice', _practice[voice](title), _practiceResult[voice](title, place), focus,
                  1 + (situation + activity) % 3, _sideStat(category, voice), voice % 2 == 0 ? 1 : -1),
              _choice('together', _together[voice](title), _togetherResult[voice](title, place), Stat.social,
                  1 + effort, Stat.happiness, 1 + voice % 2),
              _choice('lead', _lead[voice](title), _leadResult[voice](title, twistTitle), focus, 2 + effort,
                  Stat.happiness, -(effort - voice % 2 < 1 ? 1 : effort - voice % 2),
                  cost: twistCost * (category == 0 ? 1 : 8) + setting * 5 + activity * 10,
                  requirements: [Condition.parse('MinStat:Social:$socialMin')]),
              _choice('rest', _rest[voice](title), _restResult[voice](title, place),
                  voice % 3 == 0 ? Stat.health : Stat.happiness, 1, Stat.social, -1),
            ],
          );
        }
      }
    }
  }
}
