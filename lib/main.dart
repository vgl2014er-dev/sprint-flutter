import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/app_shell/sprint_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBQcxNZ5UAwqOIZqW5RSlRF4ZNhv6BEJpk',
        appId: '1:887189087092:android:4b3f6bd8d10518d9e4c221',
        messagingSenderId: '887189087092',
        projectId: 'sprint-app-10419',
        databaseURL:
            'https://sprint-app-10419-default-rtdb.europe-west1.firebasedatabase.app',
        storageBucket: 'sprint-app-10419.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const ProviderScope(child: SprintApp()));
}
