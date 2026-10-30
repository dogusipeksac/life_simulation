# Gizlilik Politikası — Hayat Simülasyonu

Yürürlük: 30 Ekim 2026  
Geliştirici: Doğuş İpeksaç  
Web’e koymak için aynı metnin HTML’i: `store/privacy.html`

Hayat Simülasyonu çevrimdışı bir oyundur. Hesap açmaz, buluta kayıt göndermez ve oyun ilerlemeni kendi sunucularımızda tutmayız.

## 1. Cihazda kalan veriler
- Hayat kaydı (ad, yaş, seçimler, istatistikler, günlük)
- Hikâye ilerlemesi ve başarımlar
- Görünüm tercihleri (tema, yazı boyutu, ses, titreşim)

Uygulama silinince bu kayıt da silinir.

## 2. Şifreleme
Hayat kaydı, hikâye ilerlemesi, başarımlar ve satın alım önbelleği **AES-256-GCM** ile kilitlenir. Anahtar Android Keystore / iOS Keychain’dedir. Dosya kopyalanırsa düz metin okunamaz. Anahtar sunucuya gitmez. Android yedekleme ve cihaz transferi oyun dosyalarını dışarı vermez.

## 3. Toplamadığımız şeyler
Hesap, e-posta, konum takibi, analitik SDK, kendi sunucumuza giden kayıt yok.

## 4. Reklam ve satın alma
**İlk sürümde kapalı.** Sonra açılırsa AdMob (reklam kimliği / cihaz bilgisi, Google gizlilik politikası) ve Play/App Store tek seferlik satın alımlar devreye girer; ödeme bilgisi mağazadadır.

## 5. Çocuklar
Genel kitle. 13 yaş altından bile bile veri toplanmaz.

## 6. Haklar
Veri cihazındadır. Silmek: uygulamayı kaldır veya yeni hayat başlat.

## 7. İletişim
Play Console / App Store geliştirici iletişimi veya web sitenin iletişim adresi.
Paket: `com.life.simulation`
