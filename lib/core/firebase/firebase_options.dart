import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Fallback for non-web text (though config is missing)
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQgMfagJiN16By-sS4fbAM0Kf6omkSRG8',
    authDomain: 'cloudwash-6ceb6.firebaseapp.com',
    projectId: 'cloudwash-6ceb6',
    storageBucket: 'cloudwash-6ceb6.firebasestorage.app',
    messagingSenderId: '864806051234',
    appId: '1:864806051234:web:ce326d49512cc22f8a26fb',
    measurementId: 'G-QT8J7LWT3Y',
  );
}
