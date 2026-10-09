import 'package:flutter/material.dart';
import 'volunteer_dashboard_screen.dart';

/// Legacy bridge pointing to the modern, complete Volunteer Dashboard Screen.
class QuickHazardScreen extends StatelessWidget {
  const QuickHazardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VolunteerDashboardScreen();
  }
}
