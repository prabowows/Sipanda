// File generated for sipanda-semarang project configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_key_sipanda_semarang',
    appId: '1:473127137460:web:sipanda_semarang_app',
    messagingSenderId: '473127137460',
    projectId: 'sipanda-semarang',
    authDomain: 'sipanda-semarang.firebaseapp.com',
    storageBucket: 'sipanda-semarang.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_key_sipanda_semarang',
    appId: '1:473127137460:android:sipanda_semarang_app',
    messagingSenderId: '473127137460',
    projectId: 'sipanda-semarang',
    storageBucket: 'sipanda-semarang.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_placeholder_key_sipanda_semarang',
    appId: '1:473127137460:ios:sipanda_semarang_app',
    messagingSenderId: '473127137460',
    projectId: 'sipanda-semarang',
    storageBucket: 'sipanda-semarang.appspot.com',
    iosBundleId: 'com.sipanda.semarang',
  );
}
