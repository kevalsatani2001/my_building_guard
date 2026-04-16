import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Returns a ready-to-use default Firebase app.
/// If app is not initialized yet (rare startup race), initialize it safely.
Future<FirebaseApp> ensureDefaultFirebaseApp() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  return Firebase.app();
}
