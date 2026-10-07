import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/component3_relief_tracking/presentation/screens/camp_dashboard_screen.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

   
  
  runApp(const LifeLineApp());
}

class LifeLineApp extends StatelessWidget {
  const LifeLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeLine - Relief Tracking',
      home: CampDashboardScreen(),
    );
  }
}
