import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/responsive/screen_fit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/services/notification_service.dart';
import 'core/services/offline_sync.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((_) => debugPrint('Firebase initialized successfully'))
      .catchError((e) => debugPrint('Firebase init error: $e'));

  // Keep data on the phone and sync it when the internet returns.
  OfflineSync.init();

  // Initialize Notifications
  await NotificationService.instance.initialize();

  // Load the saved Dark / Light choice (also sets the status bar colours).
  await ThemeController.instance.load();

  runApp(const WeSafeApp());
}

class WeSafeApp extends StatelessWidget {
  const WeSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: NotificationService.messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'WeSafe — Flood Relief & Early Warning',
      theme: AppTheme.dark,
      builder: ScreenFit.appBuilder,
      home: const SplashScreen(),
    );
  }
}