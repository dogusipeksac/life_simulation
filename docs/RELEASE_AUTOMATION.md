# Yerel mağaza sürümü

`./scripts/release.sh` mevcut Flutter projesinde Android AAB ve iOS IPA üretir; gerçek çalıştırmada Fastlane ile seçilen mağazaya yükler. Komut kendi başına Play production yayını veya App Store inceleme başvurusu yapmaz. Bu otomasyonun oluşturulması hiçbir mağaza yüklemesi başlatmaz.

## Projeye özgü durum

- Flutter 3.47.7 / Dart 3.13.5 sistemde doğrudan `flutter` komutuyla kullanılıyor; FVM yok. `pubspec.yaml` içindeki `version: 1.0.0+1` tek kaynak. Build sırasında `--build-name` ve platforma özgü `--build-number` verilir; başarılı gerçek yüklemenin ardından `pubspec.yaml` güncellenir. Uygulama arayüzünde ikinci bir sürüm sabiti bulunmadı.
- Android uygulama kimliği `com.life.simulation`, release variant tek, flavor yok. `android/app/build.gradle.kts` geçerli `android/key.properties` yoksa debug anahtarına düşüyor; release komutu dosya ve keystore bulunmadan build başlatmaz. Mevcut `tools/build_android_release.sh` korunur; yeni komut aynı `MONETIZATION_LIVE=false`, `AD_TEST_MODE=false`, obfuscation ve split-debug-info davranışını kullanır.
- iOS workspace `ios/Runner.xcworkspace`, paylaşılan scheme `Runner`, bundle ID `com.life.simulation`, team `659VRL92D3`, signing Automatic. App Store IPA export için Xcode'dan alınmış gerçek `ExportOptions.plist` gerekir. Otomasyon profil veya sertifika üretmez.
- Yerel çalışma ağacında önceden değişiklikler bulunduğu için komut otomatik commit yapmaz. `--git-record` ancak sürüm dosyaları dışındaki ağaç temizken kullanılabilir.
- İlk kurulum kontrolünde `flutter analyze` 64 lint uyarısıyla, `flutter test` 21 başarısız testle bitti. Release komutu bunları kalite kapısı olarak çalıştırır ve düzeltilene kadar build/yüklemeye geçmez.
- `README.md` eski Godot paketini `com.dogusipeksac.vita`, mevcut Flutter paketini `com.life.simulation` olarak anlatıyor. **Bu paket mevcut Play uygulamasının güncellemesi olmayabilir.** `release.env` içindeki iki kimliği ilgili mağaza kayıtlarıyla doğrulamadan gerçek yükleme başlatmayın. Kimlikler otomasyon tarafından değiştirilmez. `MONETIZATION_LIVE=false` kalır; satın alma/reklam açma bu sürüm komutunun kapsamında değil.

## İlk kurulum

Mac'te Flutter/Dart, Java 17, Android SDK, Xcode, CocoaPods, Ruby ve Bundler kurulu olmalı. `flutter doctor -v` ile sorunları giderin. `bundle config set --local path vendor/bundle` ve ardından `bundle install` çalıştırın. `Gemfile.lock` sürümleri sabitler; gemler `vendor/bundle` altında ve Git dışında tutulur.

`mkdir -p ~/.config/life-simulation && cp config/release.env.example ~/.config/life-simulation/release.env && chmod 600 ~/.config/life-simulation/release.env` komutuyla örneği kopyalayın. Bu dosya *shell olarak çalıştırılmaz*; yalnız düz `KEY=VALUE` satırları okunur. `~/.config/life-simulation` içindeki gerçek JSON, `.p8`, keystore ve plist dosyalarını repoya koymayın. Örnek kimlikler mevcut koddan alınmıştır; mağaza kaydında doğrulayın.

Android için `android/key.properties` ve gösterdiği upload keystore gerekli. Mevcut `android/create_keystore.sh` yalnız **yeni** keystore üretir. Play'e daha önce yüklenmiş uygulama için eski upload anahtarını koruyun; yenisini oluşturmak güncelleme imzasını bozabilir. Play Console uygulamasını oluşturun, Google Play Developer API ve servis hesabı erişimini ayarlayın, servis hesabına ilgili uygulamada sürüm yükleme yetkisi verin. JSON yolunu `PLAY_JSON_KEY` olarak yazın. İlk mağaza kaydı, politika formları ve gerekli Play Console ayarları manuel tamamlanmalıdır.

iOS için Apple Developer dağıtım sertifikası ve App Store provisioning profilinin Xcode Automatic Signing ile kullanılabildiğini doğrulayın. Xcode Organizer'dan başarılı App Store export sonrası oluşan `ExportOptions.plist` dosyasını `~/.config/life-simulation/` altında saklayın ve `IOS_EXPORT_OPTIONS_PLIST` değerini ayarlayın. App Store Connect'te uygun erişimli API key oluşturun; issuer ID, key ID ve `.p8` yolunu ayarlayın. App Store Connect uygulama kaydı, sözleşmeler, vergi/banka ve ilk sürüm formları manuel tamamlanmalıdır.

## Komutlar

Her hedef sürüm için `release_notes/1.2.3/android.txt` ve `release_notes/1.2.3/ios.txt` dosyalarını hazırlayın; yalnız seçilen platformun dosyası gerekli. Android `tr-TR` için en çok **500 Unicode karakter**, App Store `tr` What's New için en çok **4000 karakter** kabul edilir. TestFlight'ta iOS dosyası Fastlane `pilot` `changelog` alanı aracılığıyla **What to Test** olarak yüklenir. Dosyalar boş olamaz.

```sh
./scripts/release.sh 1.2.3 --dry-run
./scripts/release.sh 1.2.3 --android --track internal
./scripts/release.sh 1.2.3 --android --track alpha --android-build-number 45
./scripts/release.sh 1.2.3 --ios --ios-build-number 46
./scripts/release.sh 1.2.3 --testflight
./scripts/release.sh 1.2.3
./scripts/release.sh 1.2.3 --android --track production --release-status completed
./scripts/release.sh 1.2.3 --android --git-record
```

Varsayılan Android track `internal`, release status `draft`tır. `draft` mağazada taslak sürüm oluşturur; `completed` seçilen track'e dağıtımı başlatabilir. `production` veya `completed` gerçek kullanıcılara erişim sağlayabilir. `--testflight` IPA'yı yükler ve işlendikten sonra What to Test metnini ekler; test gruplarına dağıtmaz. `--ios` App Store Connect'e IPA ve What's New gönderir; incelemeye sunma ve yayınlama manueldir.

`--dry-run` gerçek ön kontroller, analiz, test ve imzalı build'i çalıştırır; mağaza API doğrulaması yapmaz, yüklemez, commit/tag yapmaz, `pubspec.yaml` ve sürüm durumunu değiştirmez. Play Fastlane `validate_only` yalnız Google Play API'sine uzak doğrulama gönderir ve tam bir yerel prova değildir; bu yüzden dry-run'da çağrılmaz. Mevcut analiz/test hataları çözülmeden dry-run da build aşamasına geçmez.

## Build numarası ve kayıt

İlk tahmin `pubspec.yaml` build numarasıdır; yeni sürümde bir artırılır. Mağaza geçmişini otomatik sorgulamaz. **Gerçek en yüksek numarayı Play Console ve App Store Connect'te kontrol edin**; gerekirse `--android-build-number` ve `--ios-build-number` verin. Mağazaya yüklenmiş numara tekrar kullanılamayabilir. Aynı sürüm tekrar denendiğinde `dist/releases/<sürüm>/state.json` numarayı korur. Yükleme başlamadan `attempted`, Fastlane başarıyla bittiğinde `uploaded` yazılır. `attempted` durumunda mağazayı kontrol edip kaydı elle uzlaştırmadan tekrar denemeyin. Önceki platform `uploaded` ise komut onu yeniden yüklemez; kalan platformu `--android` veya `--ios` ile çalıştırın. Build/IPA, split-debug-info ve varsa Android mapping `dist/releases/<sürüm>/<platform>/<build>/` altında tutulur; iOS archive/dSYM ayrıca `build/ios/archive/` altındadır. Bunları güvenli yedekleyin. Split-debug-info sembolleri olmadan obfuscation sonrası stack trace çözülemez.

`--git-record` yalnız temiz Git ağacında sürüm notları ve `pubspec.yaml` için yerel commit, platforma özgü `v<sürüm>-android` / `v<sürüm>-ios` tag'i oluşturur. Sonradan diğer platform aynı sürümü tamamlayabilir. Tag üzerine yazılmaz, `git push` yapılmaz. Varsayılan kapalıdır.

## Sorun giderme

- `release_notes/... eksik`: hedef platformun notlarını yazın.
- `Android upload keystore bulunamadı`: `android/key.properties` içindeki `storeFile` yolunu ve mevcut anahtarı kontrol edin. Debug imzasıyla yüklemeyin.
- `ExportOptions.plist bulunamadı`: Xcode'da App Store için archive/export yapıp gerçek export ayarını kaydedin.
- `Fastlane gemleri eksik`: `bundle install` çalıştırın.
- Build numarası reddedildi: mağazadaki en yüksek numarayı kontrol edip yeni sürüm denemesi için kaydı uzlaştırın; yüklendiği belirsiz numarayı körlemesine yeniden kullanmayın.
- Apple işleme süresi değişir; Fastlane çıkışı başarısızsa App Store Connect'te build durumunu kontrol edin. Bir platformun başarılı olması diğerinin başarılı olduğu anlamına gelmez.

Kaynaklar: [Flutter iOS dağıtımı](https://docs.flutter.dev/deployment/ios), [Fastlane Play yükleme](https://docs.fastlane.tools/actions/upload_to_play_store/), [Fastlane TestFlight](https://docs.fastlane.tools/actions/pilot/), [Fastlane App Store](https://docs.fastlane.tools/actions/deliver/), [Google Play sürüm notu sınırı](https://support.google.com/googleplay/android-developer/answer/9859348), [Apple What's New sınırı](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
