# Mağaza metinleri ve yayın planı

## Görseller (tools/store_art.py ile yeniden üretilir)
- Play simgesi: `store/play/icon_512.png` (512×512)
- Özellik grafiği: `store/play/feature_graphic_1024x500.png`
- Telefon ekran görüntüleri (9:16, 1080×1920): `store/play/screenshots/` (8 adet)
- App Store 6.9" (1320×2868): `store/appstore/6.9in/`
- Uygulama simgeleri: Android (uyarlanabilir + temalı tek renk) ve iOS AppIcon üretildi (`dart run flutter_launcher_icons`)

## Google Play
**Uygulama adı (≤30):** Hayat Simülasyonu: Bir Hayat
**Kısa açıklama (≤80):** Doğumdan yüz yaşına kararlarınla yazılan bir hayat ve dallanan hikâyeler.

**Tam açıklama:**
Hayat Simülasyonu, bir hayatı baştan sona yaşadığın, metin tabanlı ve tamamen Türkçe bir hayat oyunu.

KADERİNİ SEN SEÇMEZSİN
Adını sen koyarsın; ama hangi şehirde, hangi ailede, kimin yanında doğacağını ve nasıl biri olacağını kader belirler. Her hayat bambaşka başlar.

SADECE OKUMA, YAŞA
Bebeğini ninniyle uyut, bisiklette dengeni bul, ilk maaşını kira ve fatura arasında paylaştır, satılık evin rutubetini fark et. Hayatın içine serpiştirilmiş 66 etkileşimli an: nefes, zamanlama, eşleştirme, bütçe, sıralama, bilgi soruları.

HER KARARIN BİR İZİ VAR
500'den fazla olay ve hayatın koşullarına göre açılan sahneler. Seçimlerin aileni, işini, sağlığını ve ilişkilerini değiştirir; yıllar sonra karşına çıkar.

KARİYER, AİLE, İLİŞKİLER
103 meslek, terfiler ve maaşlar; okul, sınavlar, evlilik, çocuklar, kayıplar. Hayat hedefleri ve sekiz farklı final.

HİKÂYE KÜTÜPHANESİ
Başka bir hayat dene: şifre çözdüğün, kanıtları sıraladığın, frekans yakaladığın, süreli kararlar verdiğin dallanan hikâyeler. İlk kitap "Son Vapur" açık ve ücretsiz; yeni kitaplar yakında geliyor.

HESAPSIZ
Hesap gerekmez; kaydın yalnızca cihazında durur. Oyun ücretsizdir ve reklam içerir; ödüllü reklamları izlemek her zaman isteğe bağlıdır. Bütün karakterler, kurumlar ve olaylar kurgusaldır.

**Kategori:** Oyunlar › Simülasyon · **Etiketler:** hayat simülasyonu, metin oyunu, interaktif hikâye

## App Store
**Ad (≤30):** Hayat Simülasyonu - Kararlar
**Alt başlık (≤30):** Kararlarınla yazılan bir hayat
**Tanıtım metni (≤170):** Doğumdan yüz yaşına bir hayat: kaderle gelen bir aile, 66 etkileşimli an, 103 meslek ve şifrelerle dolu dallanan hikâyeler. Ücretsiz, hesapsız.
**Anahtar kelimeler (≤100):** hayat,simülasyon,hikaye,metin,oyun,karar,interaktif,roman,türkçe,kariyer,aile
**Destek URL:** https://github.com/dogusipeksac/life_simulation
**Gizlilik Politikası URL:** https://dogusipeksac.com/privacy-policy/life-simulation/
**Telif Hakkı:** 2026 Doğuş İpeksaç
**Bundle ID:** com.dogusipeksac.lifesimulation
**Apple ID:** 6830319257
**Açıklama:** Play tam açıklamasıyla aynı.

## Sürüm notu (ilk sürüm)
İlk sürüm: kaderle başlayan hayatlar, 66 etkileşimli an, kariyer ve ilişkiler, ilk hikâye kitabı "Son Vapur". Yeni kitaplar yakında.

## Reklam yerleşimi (v1)
- **Ödüllü (isteğe bağlı):** hayat bitince "İkinci şans", Profil'de "Derin bir nefes", İlişkiler'de "+3 etkinlik hakkı" (yaşta bir kez).
- **Geçiş:** hayatta en erken 8. karardan sonra, en az 10 karar ve 3 dakika arayla; yeni hayata başlarken ve kütüphanede bölüm geçişinde (uygulama açıldıktan 4 dk sonra, 3 dk aralık). Satın alma kapalı (`PURCHASES_LIVE=false`).
- Debug/profil yapılarında Google test reklamları; release'te gerçek kimlikler (`AD_TEST_MODE` ile zorlanabilir).

## Veri güvenliği (Play) · gizlilik etiketi (App Store)
- Oyun verisi yalnızca cihazda, AES-256-GCM ile kilitli; hesap yok, analitik SDK'sı yok, yedekleme kapalı.
- **Reklam içeriyor: Evet** (Play › Uygulama içeriği › Reklamlar).
- Google Mobile Ads SDK nedeniyle beyan et: **Cihaz veya diğer kimlikler** (reklam kimliği), **Uygulama etkinliği** (uygulama etkileşimleri), **Uygulama bilgileri ve performansı** (çökme/teşhis) → toplanır, üçüncü tarafla paylaşılır, amaç "Reklam veya pazarlama", "Analiz", "Dolandırıcılığı önleme"; aktarımda şifreli; kullanıcı silme talebi: Google'a yönlendir.
- App Store gizlilik etiketi: "Sizi izlemek için kullanılan veriler: Tanımlayıcılar (Reklam verisi)" ve "Size bağlı olmayan veriler: Kullanım verisi, Teşhis". Info.plist'te SKAdNetwork listesi ve ATT metni hazır.
- AdMob konsolunda **GDPR ve ABD eyalet** mesajlarını (UMP) yayımla; uygulama Profil › "Reklam gizlilik seçenekleri" ile açıyor.
- `app-ads.txt`: geliştirici web sitesinin köküne `google.com, pub-1381327816086955, DIRECT, f08c47fec0942fa0` satırını koy; Play/App Store'daki web sitesi alanı bu alan adı olmalı.
- Gizlilik politikası: `store/privacy.html` (web sitesine yükle; Play/App Store formuna URL yaz).

## Yayın kontrol listesi (v1)
- AAB: `build/app/outputs/bundle/release/app-release.aab` (upload anahtarıyla imzalı); `build/symbols` klasörünü sakla (obfuscation çözümü).
- Play: içerik derecelendirme anketi, hedef kitle 13+ (reklam olduğu için çocuklara yönelik seçme), veri güvenliği formu, gizlilik politikası URL'si.
- iOS: `pod install` + Xcode'da Archive (bu makinede CocoaPods yok); App Store Connect'te ATT ve gizlilik etiketi.

## 14 günlük kapalı test (yeni kişisel geliştirici hesapları)
Kural: üretime çıkmadan önce kapalı testte **en az 12 test kullanıcısı**, **14 gün kesintisiz** katılmış olmalı.
1. Play Console › Test › Kapalı test › yeni kanal ("Arkadaşlar"), AAB yükle: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` (önce `android/key.properties`).
2. Test kullanıcıları: bir Google Grubu oluştur, 15–20 kişi ekle (12 altına düşmemek için fazla).
3. Davet mesajı (aşağıda) ile katılım bağlantısını gönder; herkes "Test kullanıcısı ol"a basıp uygulamayı Play'den kursun ve en az birkaç gün açsın.
4. 14 gün boyunca 1–2 güncelleme yayınla (aktif test kanıtı), geri bildirimleri not al.
5. 14. günden sonra Play Console › Panel › "Üretime erişim başvurusu"nu doldur.

**Test daveti:**
Merhaba! Hayat Simülasyonu adında, kararlarınla bir hayatı baştan sona yaşadığın Türkçe bir oyun yaptım. Google Play'e çıkmadan önce 14 günlük kapalı testten geçmesi gerekiyor. Bağlantıdan "Test kullanıcısı ol"a basıp Play Store'dan kurar mısın? 14 gün boyunca silmemen ve arada bir açman yeterli. Görüşlerini de çok isterim: [katılım bağlantısı]

**Kapalı test sürüm notu:** Kapalı test sürümü. Lütfen hata, yazım yanlışı ve sıkıldığın anları bildir.
