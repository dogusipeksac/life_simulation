# vita · Hayat Simülasyonu

Godot/C# kaynak oyunun çevrimdışı Flutter dönüşümü. Türkçe içerik ve oyun dengesi kaynak projeden taşınır. Android önceliklidir; oyun kuralları `lib/game/` altında saf Dart'tır.

## Durum

P0–P2: tema ve bileşenler, içerik doğrulama, anlatı yönetmeni, çekirdek döngü, dört adımlı karakter oluşturma, sonuç ve oyun sonu ekranı, atomik v6 kayıt ve sürüm geçişleri.

P3: kariyer/okul, profil, ilişkiler, aktiviteler ve menü bağlantıları tamamlandı.

- Kariyer: 103 meslek, dönemlik ilanlar, tüm katalogda arama, başvuru şartları/şansı, 90 günlük bekleme, kaderine güven, terfi, maaş ve emeklilik.
- Okul: otomatik ilköğretim/lise, hikâye seçimleriyle üniversite/yüksek lisans, mezuniyet ve yıllık eğitim kazanımı.
- Ekonomi: aylık gelir/gider, aile desteği, borç/faiz/iflas, faizsiz banka, ev/araba giderleri ve takı cüzdanı.
- İlişkiler: kişi detayları, bağlar, arkadaşlık/partnerlik, evlilik hazırlığı/tören/takı ve yıllık yaşlanma.
- Aktiviteler: yılda 12 hak, kişi/etkinlik bazında 30 günlük bekleme; yüz–isim ve renk eşleştirme mini oyunları. Ödül, tamamlanan beş turun sonunda yalnızca bir kez verilir.
- Menü: günlük, finans, kurgusal ülke ve seçimler, karar nitelikleri, hayat hedefleri; kalıcı tema/ses/titreşim/animasyon tercihleri.
- Gezinme: alt sekmeler, üst menü, alt sayfalardan geri dönüş ve menüde çıkış onayı. Sekme geçişleri bekleyen hikâyeyi tüketmez.

Sıradaki aşamalar: P4 hikâye kütüphanesi/okuyucu/paywall; P5 satın alma, reklam, başarımlar ve kapsamlı final/ikinci şans; P6 son erişilebilirlik, performans ve release imzalama. Release yapılandırması geliştirme anahtarıyla imzalanır; mağaza yayınına hazır değildir.

## Çalıştırma ve doğrulama

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

Testler içerik şemalarını, belirlenimci oyun akışını, kayıt geçişlerini, okul/bütçe/kariyer kurallarını, banka ve etkinlik sınırlarını, seçim/düğün devamlılığını ve mini oyun ödüllerini kapsar. P3 sayfaları 320/360/411 dp genişlikte, açık/koyu temada ve büyütülmüş metinle yerleşim testinden geçer.

Android APK çıktıları: `build/app/outputs/flutter-apk/`. Oyun kaydı uygulama destek dizinindeki `savegame.json` dosyasında; arayüz tercihleri `shared_preferences` ile ayrı saklanır. Kaynak Godot projesi değiştirilmez.
