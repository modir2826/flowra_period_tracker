import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyBdLSuPzne_K6QSL_NV4axlCxc3vws586E",
        authDomain: "flowra-9584d.firebaseapp.com",
        projectId: "flowra-9584d",
        storageBucket: "flowra-9584d.appspot.com",
        messagingSenderId: "66418808535",
        appId: "1:66418808535:web:c3c7bb510f2a66f0478292",
        databaseURL:
            "https://flowra-9584d-default-rtdb.asia-southeast1.firebasedatabase.app",
      );
    }

    // fallback (mobile – safe)
    return const FirebaseOptions(
      apiKey: "dummy",
      appId: "dummy",
      messagingSenderId: "dummy",
      projectId: "flowra-9584d",
    );
  }
}
