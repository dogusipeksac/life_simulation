import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:life_simulation/firebase_options.dart';

/// Firebase ve Crashlytics ilklendirmesi.
///
/// Firebase henüz yapılandırılmamışsa veya geçici bir ağ hatası olursa
/// uygulamanın ilk açılışını kesinlikle bloklamaz.
Future<void> bootstrapFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      if (DefaultFirebaseOptions.isConfigured) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 8));
      } else {
        // Native dosyalardan (google-services.json / GoogleService-Info.plist) oku
        await Firebase.initializeApp().timeout(const Duration(seconds: 8));
      }
    }

    final crashlytics = FirebaseCrashlytics.instance;

    if (kDebugMode) {
      // Geliştirme ortamında kuyruktaki raporları gönderip otomatik toplamayı durdur
      await crashlytics.setCrashlyticsCollectionEnabled(true);
      await crashlytics.sendUnsentReports();
      await crashlytics.setCrashlyticsCollectionEnabled(false);
    } else {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
    }

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      debugPrint('[firebase] Firebase ve Crashlytics başarıyla ilklendirildi.');
    }
  } catch (error, stack) {
    if (kDebugMode) {
      debugPrint('[firebase] Henüz Firebase yapılandırılmadı veya hata oluştu: $error');
      debugPrint('$stack');
    }
  }
}
