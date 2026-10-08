import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() {
  runApp(const WeSafeApp());
}

class WeSafeApp extends StatelessWidget {
  const WeSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeSafe',
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}