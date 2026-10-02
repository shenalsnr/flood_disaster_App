import 'package:flutter/material.dart';
import 'features/component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';

void main() {
  runApp(const WeSafeApp());
}

class WeSafeApp extends StatelessWidget {
  const WeSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeSafe - Relief Tracking',
      home: CampDashboardScreen(),
    );
  }
}
