# P5 doğrulama notları

Tarih: 28 Ekim 2026

- `flutter analyze`: başarılı.
- `flutter test`: 88 test başarılı. Testler başarımları, hayat özetini, reklam koşullarını, ödülün yalnızca tamamlanan reklamdan sonra verilmesini, kayıt hatasında geri almayı ve aynı oturumda yeniden denemeyi kapsar. Satın alma testleri doğrulanmamış, bekleyen ve reddedilmiş işlemleri, onay koşullarını, geri yüklemeyi, işlem yarışlarını ve RSA anahtarlarının PKCS#1 ve SubjectPublicKeyInfo biçimlerini kapsar. Reklam ve mağaza akışları bu testlerde sahte servislerle çalıştırılır.
- `flutter build apk --release --split-per-abi`: başarılı. Çıktılar: armeabi-v7a 22,4 MB, arm64-v8a 24,7 MB, x86_64 26,2 MB. x86_64, 25 MB hedefini aşıyor; boyut iyileştirmesi P6'da ele alınmalı.
- Android arm64 emülatöründe, farklı paket adıyla oluşturulan geçici debug uygulaması yüklendi ve açıldı; gizlilik ekranı ve resmi test kimlikleri kullanıldığına dair açıklama görüntülendi. Geçici uygulama daha sonra kaldırıldı. Gerçek reklam gösterimi, ödüllü reklamın yerel SDK üzerinden tamamlanması ve Play satın alımı bu kontrolde doğrulanmadı.

## Yayın öncesi açık işler

- Play Console ürünleri, açık anahtar, yayın imzası ve gerçek mağaza hesabıyla satın alma/geri yükleme testleri gerekiyor. Anahtar verilmediğinde Android satın alımları kapalıdır; iOS için StoreKit doğrulaması henüz uygulanmamıştır.
- Godot kaynak paket adı `com.dogusipeksac.vita`, Flutter Android paket adı `com.life.simulation.life_simulation`. Mevcut Play uygulamasına güncelleme veya geçmiş satın almaların geri yüklenmesi hedefleniyorsa paket adı ve imza sürekliliği doğrulanmalı.
- AdMob canlı kimlikleri ve gerekli gizlilik ayarları yapılandırılmalı; gerçek cihazda test reklamı ve rıza akışı doğrulanmalı. Mevcut sürüm varsayılan olarak resmi test kimliklerini kullanır.
- Kayıt hatasından sonra bekleyen reklam ödülü, aynı hayat ve uygulama oturumu içinde tekrar kaydedilebilir. Uygulama kapatılırsa bellekteki bekleyen ödül korunmaz.
