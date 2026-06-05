import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA0qt29Tcga3GlSEgBslAa7Qldng64lAzE',
    appId: '1:545323837953:android:d84967489dbda87a282e00',
    messagingSenderId: '545323837953',
    projectId: 'orderpilot-pro',
    storageBucket: 'orderpilot-pro.firebasestorage.app',
    databaseURL: 'https://orderpilot-pro-default-rtdb.firebaseio.com',
  );

  // iOS not configured — add GoogleService-Info.plist if needed
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0qt29Tcga3GlSEgBslAa7Qldng64lAzE',
    appId: '1:545323837953:android:d84967489dbda87a282e00',
    messagingSenderId: '545323837953',
    projectId: 'orderpilot-pro',
    storageBucket: 'orderpilot-pro.firebasestorage.app',
    iosBundleId: 'com.orderPilotPro.orders',
  );
}
