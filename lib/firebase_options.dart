// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA3LJUuzvmIFQHmPdBLC5ilS-N46wINebY',
    appId: '1:76806992636:web:c2e69bae5e7c4408679d79',
    messagingSenderId: '76806992636',
    projectId: 'greeners-v1',
    authDomain: 'greeners-v1.firebaseapp.com',
    storageBucket: 'greeners-v1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcmnmM6PkrXlarlibmJj4kQLU96UQEWxo',
    appId: '1:76806992636:android:7438d81c538a9632679d79',
    messagingSenderId: '76806992636',
    projectId: 'greeners-v1',
    storageBucket: 'greeners-v1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqDlISmPUs7NWBs4gJ6LlqARPD99GukHw',
    appId: '1:76806992636:ios:ccbce2152ae6258e679d79',
    messagingSenderId: '76806992636',
    projectId: 'greeners-v1',
    storageBucket: 'greeners-v1.firebasestorage.app',
    iosBundleId: 'com.example.firstly',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAqDlISmPUs7NWBs4gJ6LlqARPD99GukHw',
    appId: '1:76806992636:ios:ccbce2152ae6258e679d79',
    messagingSenderId: '76806992636',
    projectId: 'greeners-v1',
    storageBucket: 'greeners-v1.firebasestorage.app',
    iosBundleId: 'com.example.firstly',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA3LJUuzvmIFQHmPdBLC5ilS-N46wINebY',
    appId: '1:76806992636:web:b948dde022163e70679d79',
    messagingSenderId: '76806992636',
    projectId: 'greeners-v1',
    authDomain: 'greeners-v1.firebaseapp.com',
    storageBucket: 'greeners-v1.firebasestorage.app',
  );

}