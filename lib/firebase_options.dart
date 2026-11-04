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
    apiKey: 'TODO_FIREBASE_ANDROID_API_KEY',
    appId: 'TODO_FIREBASE_ANDROID_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    storageBucket: 'TODO_PROJECT_ID.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO_FIREBASE_IOS_API_KEY',
    appId: 'TODO_FIREBASE_IOS_APP_ID',
    messagingSenderId: 'TODO_SENDER_ID',
    projectId: 'TODO_PROJECT_ID',
    storageBucket: 'TODO_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.dogusipeksac.lifesimulation',
  );
}
