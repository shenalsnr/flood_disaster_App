import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Component 1: Evacuation & Early Warning (Import preserved for component integration)
// ignore: unused_import
import 'features/component1_evacuation/presentation/screens/citizen_dashboard_screen.dart';
// Component 3: Relief Equipment & Camp Tracking (Your Component)
import 'features/component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E676),
          secondary: const Color(0xFF40C4FF),
          surface: const Color(0xFF1A1A1A),
          error: const Color(0xFFFF5252),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E676),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        ),
      ),
      // Set to your feature (Component 3: Relief Tracking).
      // Component 1 (CitizenDashboardScreen) is also imported above if needed.
      home: const CampDashboardScreen(),
    );
  }
}

