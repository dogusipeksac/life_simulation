# Hayat Simülasyonu

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

P4: hikâye kütüphanesi, okuyucu ve bölüm kilidi tamamlandı.

- Üç kitap ve kaynak SVG kapakları; Tümü/Ücretsiz/Kitaplığım filtreleri. Kütüphaneye açılış ekranından ve oyun menüsünden erişilir.
- Koşullu kararlar, hikâyeye özel statlar, seçim sonuçları ve 12 farklı sonun koleksiyonu.
- Okuyucuda A−/A+ yazı boyutu tercihi, otomatik kayıt, kaldığın yerden devam ve sonları koruyarak yeniden başlatma. Noto Serif Regular/Medium/SemiBold fontları lisansıyla paketlenir; çalışma anında font indirme kapalıdır.
- Hikâyeler ayrı `story-progress.json` dosyasına atomik yazılır. Bozuk kayıt kurtarma ve yazım hatasında kararın geri alınması desteklenir. Yeni hayat başlatmak kitap ilerlemesini silmez.
- Ücretli bölüm sınırı oyun servisinde uygulanır; mağaza ve sahiplik bağlantısı P5'te eklenmiştir.

P5: başarımlar, hayat özeti, ödüllü reklamlar ve Android satın alma altyapısı eklendi.

- Başarımlar hayat kayıtlarından ayrı saklanır; hayat sonunda özet ve koşullar uygunsa ikinci şans sunulur. Ödüllü reklamla nefes alma ve ikinci şans, kayıt başarısız olduğunda aynı oturumda yeniden kaydedilebilir.
- AdMob varsayılan olarak resmi test kimlikleriyle çalışır. Reklam isteği öncesinde UMP gizlilik/onay durumu kontrol edilir; gizlilik seçeneklerine uygulamadan erişilebilir.
- Google Play satın almaları paket adı, ürün, durum ve RSA imzasıyla doğrulanıp onaylandıktan sonra sahiplik verir. Play açık anahtarı yapılandırılmadığında gerçek satın alma kapalıdır. iOS satın alımları StoreKit doğrulaması uygulanana kadar kullanılamaz.
- Doğrulama sonuçları ve cihaz testi sınırları [P5 doğrulama notlarında](docs/P5_VALIDATION.md) yer alır.

Sıradaki aşama P6: erişilebilirlik, performans, boyut iyileştirmesi ve release imzalama. Mevcut release geliştirme anahtarıyla imzalanır; mağaza yayınına hazır değildir.

### Canlı mağaza ve reklam yapılandırması

Canlı kullanıma geçmeden önce Play Console'da ürünler tanımlanmalı, gerçek imzalama anahtarı kullanılmalı ve satın alma akışı test edilmelidir. Derlemeye `--dart-define=PLAY_BILLING_PUBLIC_KEY=<base64-DER-açık-anahtar>` verilir; doğrulayıcının varsayılan paket adı `com.life.simulation.life_simulation` değeridir. Paket adı değiştirilirse `BILLING_PACKAGE_NAME` da eşleştirilmelidir. Kaynak Godot projesinin paket adı `com.dogusipeksac.vita` olduğundan mevcut Play uygulamasına güncelleme ve eski satın almaların geri yüklenmesi için paket adı ve imzalama anahtarı sürekliliği ayrıca doğrulanmalıdır.

**İlk sürüm:** `MONETIZATION_LIVE` varsayılan `false` — reklam ve IAP kapalı, tüm hikâyeler açık (`lib/game/features.dart`). Açmak: `--dart-define=MONETIZATION_LIVE=true` veya `MONETIZATION_LIVE=true ./tools/build_android_release.sh`.

Kayıtlar AES-256-GCM ile kilitlenir; anahtar Keystore/Keychain’dedir. Gizlilik politikası: `store/privacy.html` (web sitesine yükle).

Android ve iOS AdMob kimlikleri projede. Geliştirmede `AD_TEST_MODE=true`. Canlı reklam birimleri için `AD_TEST_MODE=false`. Bkz. [AdMob Flutter](https://developers.google.com/admob/flutter/quick-start).

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

## Kod indeksi

Proje `codebase-memory-mcp 0.12.1` ile yerel olarak indekslenir. Kalıcı grafik `.codebase-memory/` altındadır. Yenilemek için:

```sh
codebase-memory-mcp cli index_repository --repo-path "$PWD" --mode full --persistence true
```

Bazı Dart 3 ve platform C/C++ yapıları araç tarafından kısmen çözümlenebilir; indeks eksiksiz bir derleyici analizi yerine geçmez. MCP bağlantısı mevcut oturumda görünmüyorsa aynı kurulu aracın yerel CLI'ı kullanılabilir.
