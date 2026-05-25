import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAM7shipBDQNYgR2jZN2qclxFhkT6owE9c',
    appId: '1:137930169859:android:5d690dae8a367323923836',
    messagingSenderId: '137930169859',
    projectId: 'rakhshati-dfb4c',
    storageBucket: 'rakhshati-dfb4c.firebasestorage.app',
  );
}
