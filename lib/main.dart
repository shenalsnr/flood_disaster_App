import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) => debugPrint('Firebase initialized successfully'))
      .catchError((e) => debugPrint('Firebase init error: $e'));

  // Force dark status bar icons to match the dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WeSafeApp());
}

class WeSafeApp extends StatelessWidget {
  const WeSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeSafe — Flood Relief & Early Warning',
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
