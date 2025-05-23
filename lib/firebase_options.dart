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
    apiKey: 'AIzaSyDKUtEL9FYe-oAmYTJTu4zPgW6lRABn5sE',
    appId: '1:593204508901:web:e5a26d43ef5be855637c0c',
    messagingSenderId: '593204508901',
    projectId: 'kagame-432309',
    authDomain: 'kagame-432309.firebaseapp.com',
    storageBucket: 'kagame-432309.firebasestorage.app',
    measurementId: 'G-C1GZV58WWF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0pUVqjo3mOASx08oHwMucDYKM3oD8CbI',
    appId: '1:593204508901:android:dfcb7d632602006a637c0c',
    messagingSenderId: '593204508901',
    projectId: 'kagame-432309',
    storageBucket: 'kagame-432309.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAEoJMYoXD8jY_bKhvu6Lvngi3YrCSvYPQ',
    appId: '1:593204508901:ios:916ecd90207121da637c0c',
    messagingSenderId: '593204508901',
    projectId: 'kagame-432309',
    storageBucket: 'kagame-432309.firebasestorage.app',
    androidClientId: '593204508901-li9o8cioopbqfhkmn8bh2bs35mobc6vn.apps.googleusercontent.com',
    iosClientId: '593204508901-f995pgea9cvvg1n64fv5gq0qcho9m7me.apps.googleusercontent.com',
    iosBundleId: 'com.kagameteam.KagaMe',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAEoJMYoXD8jY_bKhvu6Lvngi3YrCSvYPQ',
    appId: '1:593204508901:ios:0c9ed52d4013d0d2637c0c',
    messagingSenderId: '593204508901',
    projectId: 'kagame-432309',
    storageBucket: 'kagame-432309.firebasestorage.app',
    androidClientId: '593204508901-li9o8cioopbqfhkmn8bh2bs35mobc6vn.apps.googleusercontent.com',
    iosClientId: '593204508901-de20rbheavjuhe131cosg9k5s01s1dnl.apps.googleusercontent.com',
    iosBundleId: 'com.kagameteam.kagame',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDKUtEL9FYe-oAmYTJTu4zPgW6lRABn5sE',
    appId: '1:593204508901:web:cfb7a1223a4a27d1637c0c',
    messagingSenderId: '593204508901',
    projectId: 'kagame-432309',
    authDomain: 'kagame-432309.firebaseapp.com',
    storageBucket: 'kagame-432309.firebasestorage.app',
    measurementId: 'G-XN4H5SB3F6',
  );

}