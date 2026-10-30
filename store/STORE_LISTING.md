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
Başka bir hayat dene: şifre çözdüğün, kanıtları sıraladığın, frekans yakaladığın, süreli kararlar verdiğin uzun ve dallanan hikâyeler. "Son Vapur" tamamen ücretsiz.

ÇEVRİMDIŞI VE HESAPSIZ
İnternet ve hesap gerekmez. Kaydın yalnızca cihazında durur. Bütün karakterler, kurumlar ve olaylar kurgusaldır.

**Kategori:** Oyunlar › Simülasyon · **Etiketler:** hayat simülasyonu, metin oyunu, interaktif hikâye

## App Store
**Ad (≤30):** Hayat Simülasyonu
**Alt başlık (≤30):** Kararlarınla yazılan bir hayat
**Tanıtım metni (≤170):** Doğumdan yüz yaşına bir hayat: kaderle gelen bir aile, 66 etkileşimli an, 103 meslek ve şifrelerle dolu dallanan hikâyeler. Çevrimdışı, hesapsız.
**Anahtar kelimeler (≤100):** hayat,simülasyon,hikaye,metin,oyun,karar,interaktif,roman,türkçe,kariyer,aile
**Açıklama:** Play tam açıklamasıyla aynı.

## Sürüm notu (ilk sürüm)
İlk sürüm: kaderle başlayan hayatlar, 66 etkileşimli an, yeniden tasarlanan kariyer ve ilişkiler, uzun hikâye kitapları. Bu sürümde reklam ve satın alma yok; tüm içerik açık.

## Veri güvenliği (Play) · gizlilik etiketi (App Store)
- Oyun verisi yalnızca cihazda; hesap yok, analitik SDK'sı yok.
- AdMob (reklam) etkinse: reklam kimliği ve yaklaşık konum/cihaz bilgisi reklam sağlayıcısınca toplanabilir → "Reklam veya pazarlama" amaçlı, üçüncü tarafla paylaşılan veri olarak beyan edilmeli. Reklamlar kapalı yayınlanırsa "veri toplanmıyor".

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
