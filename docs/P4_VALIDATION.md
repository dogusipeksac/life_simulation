# P4 doğrulaması · 26 Ekim 2026

Kaynak Godot projesinin StoryLibrary, StoryBook/StoryProgress ve StoryLibraryPanel akışları Flutter'a taşındı. Üç kitap JSON'u değişmedi; kaynak SVG kapakları eklendi.

## Tamamlanan kapsam

- Açılıştan ve oyun menüsünden bağımsız hikâye kütüphanesine erişim.
- Tümü / Ücretsiz / Kitaplığım filtreleri, kapaklar, kitap bilgileri ve devam durumu.
- Bölümler, koşullu kararlar, kitap statları, seçim sonuçları ve 12 sonun koleksiyonu.
- Kalıcı A−/A+ okuma boyutu; sistem metin ölçeği ve açık/koyu tema. Noto Serif 400/500/600 fontları SIL OFL lisansıyla paketlendi, çalışma anında font indirme kapatıldı.
- Ayrı `story-progress.json` v1 kaydı: asıl / geçici / yedek okuma, atomik yazma, kayıp düğüm onarımı, seçim yazılamazsa geri alma.
- Ücretsiz başlangıçtan sonraki kilidin servis katmanında uygulanması; yeniden başlatırken keşfedilen sonların korunması.
- P4 mağazasız çalışma davranışı: satın alma kapalı, gerçek olmayan fiyat/işlem veya sahte kilit açma yok. Mağaza köprüsü ve gerçek satın alma/geri yükleme P5 kapsamındadır.

## Doğrulama

- `flutter analyze`: temiz.
- `flutter test`: 67 test geçti.
- Üç kitabın 12 sonunun tamamına gerçek stat/flag/seçim motoruyla erişim test edildi.
- Çift dokunma / eski karar kimliği, bölüm sınırı, başarısız kayıt, yedekten kurtarma, hayat kaydından bağımsızlık ve yeniden başlatma testleri geçti.
- Okuyucu, kitaplık ve paywall: 320/360/411 dp, açık/koyu tema, sistem metni 1,4 kat ve en büyük okuma yazısı ile taşma kontrolü.
- Android arm64 emülatörüne APK güncellemesi kuruldu. Emülatör başka bir uygulamada kullanılmaya başlandığı için görsel kontrol bağımsız Flutter render görüntüleriyle tamamlandı. Kütüphane kapakları, okuyucu ve bölüm kilidi ekranları incelendi. Ağ kapalıyken paketlenmiş fontların yüklenmesi ayrıca test edildi.

## Release

`flutter build apk --release --split-per-abi` başarılı:

- armeabi-v7a: 18,0 MB
- arm64-v8a: 20,5 MB
- x86_64: 22,0 MB

APK çıktıları `build/app/outputs/flutter-apk/` altında. Mağaza imzalama anahtarı P6 kapsamındadır.

## Kod indeksi

`codebase-memory-mcp 0.12.1` yerel CLI ile proje indekslendi; kalıcı grafik `.codebase-memory/` altında saklanır. Kurulum bu çalışan oturuma MCP araçları olarak eklenmediği için aynı aracın CLI yüzeyi kullanıldı. Bazı Dart 3 ve platform C/C++ sözdizimi kısmen çözümlenir; kesin kontrol için Flutter analizörü ve testler esas alınır.
