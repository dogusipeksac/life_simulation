// Firebase seçenekleri. FlutterFire CLI ile (`flutterfire configure`)
// veya Firebase Console'dan alınan değerlerle güncellenecektir.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static bool get isConfigured {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android.apiKey.isNotEmpty && !android.apiKey.startsWith('TODO');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios.apiKey.isNotEmpty && !ios.apiKey.startsWith('TODO');
    }
    return false;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for Firebase.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUcpjYgQYyw24EFpms24vNO1hO55I7b5E',
    appId: '1:655591401589:android:eaacc148aa96acc13a303c',
    messagingSenderId: '655591401589',
    projectId: 'life-simulation-71e07',
    storageBucket: 'life-simulation-71e07.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5jJdHCQNpQb8VYEZtaV0XlXaEhlVVIWE',
    appId: '1:655591401589:ios:e28e0c12a60110863a303c',
    messagingSenderId: '655591401589',
    projectId: 'life-simulation-71e07',
    storageBucket: 'life-simulation-71e07.firebasestorage.app',
    iosBundleId: 'com.dogusipeksac.lifesimulation',
  );
}
