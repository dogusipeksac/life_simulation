# P3 doğrulaması · 26 Ekim 2026

P3; kariyer/okul, profil, ilişkiler, aktiviteler ve menü/finans/günlük/ülke ekranlarını içerir. Oyun kuralları kaynak Godot projesindeki CareerSystem, EducationSystem, EconomySystem, GoalSystem, SocialLifeSystem, WeddingSystem ve LifeWorldSystem dosyalarından çevrilmiştir. Mevcut v6 kayıt şeması korunur.

## Kontroller

- `flutter test`: 48 test geçti (P2'de 36).
- `flutter analyze`: hata veya uyarı yok.
- `git diff --check`: temiz.
- P3 ekranları: 320/360/411 dp, açık/koyu tema ve 1,4 kat metin ölçeğiyle kaydırma/taşma testleri.
- Akış testleri: sekmelerde bekleyen hikâyeyi koruma, kişi etkileşimi, banka yatırma/çekme sınırları, geri dönüş, kalıcı tercihler, beş turluk mini oyun ve ödülün yalnızca bir kez verilmesi.
- Kural testleri: aylık bütçenin aynı ay tekrar uygulanmaması, maaş/emeklilik, okul/mezuniyet, hedef ödülü, yıllık aktivite bütçesi ve kayıt sonrası bekleme, seçim/düğün kararının yüklenmesi.
- Android arm64 emülatörüne release APK güncellemesi başarıyla kuruldu. Önceki kayıtla açılış ve kariyer/ilişkiler ekranlarının görünümü kontrol edildi.

## Release boyutları

`flutter build apk --release --split-per-abi` başarılı:

- armeabi-v7a: 16,7 MB
- arm64-v8a: 19,3 MB
- x86_64: 20,7 MB

Çıktılar `build/app/outputs/flutter-apk/` altında; APK dosyaları repoya eklenmez. İmzalama hâlâ geliştirme anahtarıyla yapılır. Mağaza yayını ve release anahtarı P6 kapsamındadır.

## Sonraki kapsam

P4 hikâye kütüphanesi/okuyucu/paywall; P5 başarımlar, mağaza, reklam ve genişletilmiş final/ikinci şans. Bu özellikler için P3 menüsünde işlevsiz düğmeler sunulmaz.
