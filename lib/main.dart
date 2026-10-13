import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/localization/language_controller.dart';
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

  // Load the saved language (English / Sinhala / Tamil).
  await LanguageController.instance.load();

  runApp(const WeSafeApp());
}

class WeSafeApp extends StatefulWidget {
  const WeSafeApp({super.key});

  @override
  State<WeSafeApp> createState() => _WeSafeAppState();
}

class _WeSafeAppState extends State<WeSafeApp> {
  @override
  void initState() {
    super.initState();
    LanguageController.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageController.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  /// Language changed: rebuild every screen that is already open so all the
  /// text switches at once (navigation is not reset).
  void _onLanguageChanged() {
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

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
