// firebase_options.dart — Generated Firebase configuration for Strixhaven.
// Do NOT commit this file if your project is public (API key exposure).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for web. '
          'Reconfigure with FlutterFire CLI for other platforms.',
        );
      default:
        throw UnsupportedError('Unknown platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDNQ_CKrhqzPlF41d48BfNyLyObSG2jQao',
    authDomain: 'strixhaven-manager.firebaseapp.com',
    projectId: 'strixhaven-manager',
    storageBucket: 'strixhaven-manager.firebasestorage.app',
    messagingSenderId: '280841810375',
    appId: '1:280841810375:web:c336fcc126bca018bca9e2',
  );
}
