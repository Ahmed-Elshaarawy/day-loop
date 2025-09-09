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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqZWr_5UsRdXktH3DLDEWDqAhXTOjN39E',
    appId: '1:1004936220062:android:720591f77f62abd7721a8f',
    messagingSenderId: '1004936220062',
    projectId: 'day-loop',
    storageBucket: 'day-loop.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyByE9SEMiOnb_bBxJuIaxA2CUioUyC8vRw',
    appId: '1:1004936220062:ios:aca605615056d377721a8f',
    messagingSenderId: '1004936220062',
    projectId: 'day-loop',
    storageBucket: 'day-loop.firebasestorage.app',
    androidClientId: '1004936220062-a51jn5v189ehpa1pi71r576soan4aijn.apps.googleusercontent.com',
    iosClientId: '1004936220062-fvm4ta484eskeoouchj2l38132ieni94.apps.googleusercontent.com',
    iosBundleId: 'com.example.dayLoop',
  );
}
