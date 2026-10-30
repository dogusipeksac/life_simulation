# P6 doğrulaması · 30 Ekim 2026

P6; erişilebilirlik geçişi, boyut optimizasyonu ve yayın imzası hazırlığını içerir.

## Kontroller

- `flutter test`: 118 test geçti (P5'te 88). Yeni `test/accessibility_test.dart`: 15 ekran × koyu/açık tema; `androidTapTargetGuideline` (48 dp), `labeledTapTargetGuideline` (TalkBack etiketi) ve `textContrastGuideline` (WCAG AA 4,5:1).
- `flutter analyze`: hata veya uyarı yok.
- Android arm64 emülatöründe obfuscate edilmiş release APK açıldı, kayıtlı hayata devam edildi, sekmeler gezildi; çökme yok.

## Erişilebilirlik düzeltmeleri

- Açık ("kâğıt") temada üç renk kontrast sınırının altındaydı (3,6–4,4:1). Aynı tonda koyulaştırıldı:
  `muted` 7C7488 → 696374, `accent` A9682B → 905825, `positive` 38714C ← 3F7F55. Koyu tema değişmedi (zaten 5,4:1 ve üstü).
- Alt sekme çubuğunda dar ekranda dört sekme 40 dp'ye iniyordu. "Yeni yaş" sabit 76 dp genişlikte, ikon üstte / etiket altta düzene geçti; sekmeler 320 dp'de bile ≥ 48 dp.

## Boyut

`flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols`:

| ABI | P5 | P6 |
|---|---|---|
| armeabi-v7a | 22,4 MB | 20,2 MB |
| arm64-v8a | 24,7 MB | 22,7 MB |
| x86_64 | 26,2 MB | 24,3 MB |

- Noto Serif üç ağırlık Türkçe/Latin + içerikte geçen bütün karakterlere indirgendi: 1,3 MB → 164 KB (`tools/subset_fonts.py`, kaynak tam TTF'lerle yeniden üretilebilir).
- `--obfuscate --split-debug-info`: Dart kodu küçülür; sembol dosyaları `build/symbols` altında kalır, çökme raporlarını çözmek için saklanmalı (repoya girmez).
- Kullanılmayan `cupertino_icons` kaldırıldı.
- Kalan büyük parçalar: `libflutter.so` 11,5 MB (sabit), Dart kodu 6,8 MB, `classes.dex` 2,6 MB (çoğu reklam/ödeme SDK'ları).

## Düzeltilen çökme

Release paketi açılışta çöküyordu: `Failed to create an instance of androidx.work.impl.WorkDatabase`. `google_mobile_ads`'in kullandığı WorkManager'ın Room sınıfı R8 tarafından siliniyordu. `android/app/proguard-rules.pro` ile korundu.

## Yayın imzası

- `android/app/build.gradle.kts` artık `android/key.properties` dosyasını okur; yoksa yerel denemeler için debug anahtarıyla imzalar.
- Şablon: `android/key.properties.example` (anahtar üretme komutu içinde). `key.properties` ve `*.jks` `.gitignore`'da.
- Uygulama adı Android ve iOS'ta "vita" oldu.

## Açık işler (yayın öncesi)

- Yükleme anahtarını üret ve `android/key.properties`'i doldur; Play App Signing'e kaydet.
- Paket adı: Godot sürümü `com.dogusipeksac.vita`, Flutter `com.life.simulation.life_simulation`. Mevcut Play kaydını güncellemek için aynı paket adı ve imza gerekir.
- Play'e `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` ile AAB yüklenir; kullanıcıya inen boyut yukarıdaki ABI APK'larıyla aynı mertebededir.
- Gerçek cihazda TalkBack ile elle bir tur ve 60 fps kaydırma ölçümü henüz yapılmadı.
- P5'ten kalanlar: AdMob canlı kimlikleri, Play Console ürünleri ve gerçek satın alma testi.
